-- =============================================================================
-- Administrative location tree: schema, build, and publish
-- =============================================================================
-- When to run: after osm2pgsql and sql/02-indexes.sql (imported OSM tables
-- must exist). Use psql with ON_ERROR_STOP=1:
--
--   docker compose exec -T postgis psql -U osm -d osm -v ON_ERROR_STOP=1 < sql/03-cache.sql
--
-- Slot mapping (must stay aligned with GO packages-new/providers/locations/src/levels.ts):
--   ES: admin_level 2 → 4 → 6 → 8
--   PT: admin_level 2 → 6|4 → 7 → 8  (slot 1 allows level 6 then 4 via level_order)
--
-- Geometry stays in PostgreSQL; GO reads only the published JSON from `cache`.
-- Build uses temp tables (ON COMMIT DROP). Publication and locations_dataset.ready
-- commit together; failures leave the previous tree row unchanged.

-- -----------------------------------------------------------------------------
-- Persistent cache table
-- -----------------------------------------------------------------------------
-- Schema upgrades are short transactions, separate from geometry processing.
-- Keep cached rows available while the subsequent tree build runs.
DROP TABLE IF EXISTS public.cache;
CREATE TABLE IF NOT EXISTS public.cache (
    cache_key text PRIMARY KEY,
    cache_value jsonb NOT NULL
);

-- -----------------------------------------------------------------------------
-- Build tree from OSM admin polygons and publish to cache
-- -----------------------------------------------------------------------------

BEGIN;

SET LOCAL statement_timeout = '180s';
SET LOCAL lock_timeout = '10s';

-- One concurrent build per database; readers can still scan planet_osm_polygon.
SELECT pg_advisory_xact_lock(724019836);
LOCK TABLE planet_osm_polygon IN SHARE MODE;
SELECT generation FROM locations_dataset WHERE id FOR UPDATE;

-- Per-country slot → OSM admin_level (and tie-break order within a slot).
CREATE TEMP TABLE location_tree_slots (
    country text,
    slot integer,
    admin_level text,
    level_order integer
) ON COMMIT DROP;

INSERT INTO location_tree_slots VALUES
    ('ES', 0, '2', 0), ('ES', 1, '4', 0), ('ES', 2, '6', 0), ('ES', 3, '8', 0),
    ('PT', 0, '2', 0), ('PT', 1, '6', 0), ('PT', 1, '4', 1), ('PT', 2, '7', 0), ('PT', 3, '8', 0);

-- Collect admin boundaries contained in each country polygon (slot 0).
CREATE TEMP TABLE location_tree_nodes ON COMMIT DROP AS
WITH countries AS MATERIALIZED (
    SELECT s.country, p.way
    FROM location_tree_slots s
    JOIN planet_osm_polygon p ON p.tags->>'ISO3166-1' = s.country
        AND p.boundary = 'administrative' AND p.admin_level = '2'
    WHERE s.slot = 0
)
SELECT
    s.country,
    s.slot,
    s.level_order,
    abs(p.osm_id)::text AS id,
    p.admin_level,
    p.tags->>'ref:ine' AS code,
    COALESCE(p.tags->>'int_name', p.name, abs(p.osm_id)::text) AS name,
    -- Match the precision of the GeoJSON formerly used by Turf.
    ST_GeomFromGeoJSON(ST_AsGeoJSON(p.way)) AS geom,
    NULL::geometry(Point, 4326) AS anchor,
    NULL::text AS parent_id,
    NULL::jsonb AS payload
FROM location_tree_slots s
JOIN countries c ON c.country = s.country
JOIN planet_osm_polygon p ON p.admin_level = s.admin_level
    AND p.boundary = 'administrative'
    AND ST_Within(p.way, c.way);

ALTER TABLE location_tree_nodes ADD PRIMARY KEY (country, id);
CREATE INDEX ON location_tree_nodes USING gist (geom);
CREATE INDEX ON location_tree_nodes (country, slot);
ANALYZE location_tree_nodes;

-- Refuse to publish if any configured slot has no matching polygon.
DO $check$
BEGIN
    IF EXISTS (
        SELECT country, slot FROM location_tree_slots
        EXCEPT
        SELECT country, slot FROM location_tree_nodes
    ) THEN
        RAISE EXCEPTION 'Refusing to publish a tree with a missing administrative slot';
    END IF;
    IF (SELECT count(*) FROM location_tree_nodes WHERE slot = 0) <> 2 THEN
        RAISE EXCEPTION 'Expected exactly one country root for ES and PT';
    END IF;
END;
$check$;

-- Anchor points for parent matching (Turf pointOnFeature semantics):
-- bbox center when inside the polygon, else nearest vertex by spherical distance.
UPDATE location_tree_nodes n
SET anchor = c.center
FROM (
    SELECT
        country,
        id,
        ST_SetSRID(
            ST_MakePoint(
                (ST_XMin(geom) + ST_XMax(geom)) / 2,
                (ST_YMin(geom) + ST_YMax(geom)) / 2
            ),
            4326
        ) AS center
    FROM location_tree_nodes
) c
WHERE n.country = c.country AND n.id = c.id;

UPDATE location_tree_nodes n
SET anchor = (
    SELECT v.geom
    FROM ST_DumpPoints(n.geom) v
    ORDER BY ST_DistanceSphere(v.geom, n.anchor), v.path
    LIMIT 1
)
WHERE NOT ST_Covers(n.geom, n.anchor);

-- Link each node to the nearest ancestor slot that contains its anchor.
UPDATE location_tree_nodes child
SET parent_id = (
    SELECT parent.id
    FROM location_tree_nodes parent
    WHERE parent.country = child.country
        AND parent.slot < child.slot
        AND ST_Covers(parent.geom, child.anchor)
    ORDER BY parent.slot DESC, parent.name COLLATE "en-US-x-icu",
        parent.level_order, parent.id
    LIMIT 1
)
WHERE child.slot > 0;

CREATE INDEX ON location_tree_nodes (country, parent_id);

-- Leaf payloads first; nested children are merged bottom-up in the DO block below.
UPDATE location_tree_nodes
SET payload = jsonb_build_object(
    'admin_level', admin_level,
    'children', '[]'::jsonb,
    'code', code,
    'id', id,
    'name', name
);

DO $tree$
DECLARE
    depth integer;
BEGIN
    FOR depth IN REVERSE 2..0 LOOP
        UPDATE location_tree_nodes parent
        SET payload = jsonb_set(
            parent.payload,
            '{children}',
            COALESCE(
                (
                    SELECT jsonb_agg(
                        child.payload
                        ORDER BY child.slot, child.name COLLATE "en-US-x-icu",
                            child.level_order, child.id
                    )
                    FROM location_tree_nodes child
                    WHERE child.country = parent.country
                        AND child.parent_id = parent.id
                ),
                '[]'::jsonb
            )
        )
        WHERE parent.slot = depth;
    END LOOP;
END;
$tree$;

-- Mark dataset ready and upsert the GO-facing tree array.
UPDATE locations_dataset
SET generation = generation + 1, ready = true
WHERE id;

INSERT INTO public.cache (cache_key, cache_value)
SELECT
    'locations-administrative-tree',
    (
        SELECT jsonb_agg(payload ORDER BY country, name COLLATE "en-US-x-icu", id)
        FROM location_tree_nodes
        WHERE slot = 0
    )
ON CONFLICT (cache_key) DO UPDATE
SET cache_value = EXCLUDED.cache_value;

COMMIT;