-- Run with psql ON_ERROR_STOP=1, outside a transaction (CONCURRENTLY).
-- Reapply after every osm2pgsql --create import.
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_country_idx
    ON planet_osm_polygon ((tags->>'ISO3166-1'))
    WHERE boundary = 'administrative' AND admin_level = '2';

CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_admin_level_idx
    ON planet_osm_polygon (admin_level)
    WHERE boundary = 'administrative';

-- The direct GeoJSON query requires one row per OSM relation.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_osm_id_idx
    ON planet_osm_polygon (osm_id);

-- These tables survive osm2pgsql --create. Keep the previous tree during imports.
CREATE TABLE IF NOT EXISTS locations_dataset (
    id boolean PRIMARY KEY DEFAULT true CHECK (id),
    generation bigint NOT NULL DEFAULT 1,
    ready boolean NOT NULL DEFAULT true
);
INSERT INTO locations_dataset (id) VALUES (true) ON CONFLICT (id) DO NOTHING;

ANALYZE planet_osm_polygon;
ANALYZE planet_osm_point;
