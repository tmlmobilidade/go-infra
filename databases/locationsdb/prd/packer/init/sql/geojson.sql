-- Export flex tables from config.lua into GeoJSON FeatureCollections.
-- Requires psql meta-commands (\o). Run: psql -t -A -f geojson.sql

-- Places (nodes with place=*)
\o /output/places.geojson
SELECT jsonb_build_object(
  'type', 'FeatureCollection',
  'features', COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'type', 'Feature',
          'geometry', ST_AsGeoJSON(way)::jsonb,
          'properties', jsonb_build_object(
            'osm_id', osm_id,
            'name', name,
            'place', place,
            'tags', tags
          )
        )
        ORDER BY name NULLS LAST
      )
      FROM planet_osm_point
    ),
    '[]'::jsonb
  )
);
\o

-- Administrative boundaries
\o /output/boundaries.geojson
SELECT jsonb_build_object(
  'type', 'FeatureCollection',
  'features', COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'type', 'Feature',
          'geometry', ST_AsGeoJSON(way)::jsonb,
          'properties', jsonb_build_object(
            'osm_id', osm_id,
            'name', name,
            'admin_level', admin_level,
            'boundary', boundary,
            'tags', tags
          )
        )
        ORDER BY name NULLS LAST
      )
      FROM planet_osm_polygon
    ),
    '[]'::jsonb
  )
);
\o
