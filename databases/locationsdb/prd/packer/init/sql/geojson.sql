-- Export named POIs as a GeoJSON FeatureCollection into /output.
-- Requires psql meta-commands (\o), so run via: psql -f geojson.sql

\o /output/pois.geojson
SELECT jsonb_build_object(
  'type', 'FeatureCollection',
  'features', COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'type', 'Feature',
          'geometry', ST_AsGeoJSON(geom)::jsonb,
          'properties', jsonb_build_object(
            'osm_type', osm_type,
            'osm_id', osm_id,
            'name', name,
            'class', class,
            'subclass', subclass
          )
        )
        ORDER BY name
      )
      FROM pois
    ),
    '[]'::jsonb
  )
);
\o
