local tables = {}

tables.polygon = osm2pgsql.define_area_table('planet_osm_polygon', {
    { column = 'osm_id', type = 'bigint' },
    { column = 'name', type = 'text' },
    { column = 'admin_level', type = 'text' },
    { column = 'boundary', type = 'text' },
    { column = 'tags', type = 'jsonb' },
    { column = 'way', type = 'geometry', projection = 4326, not_null = true },
})

tables.point = osm2pgsql.define_node_table('planet_osm_point', {
    { column = 'osm_id', type = 'bigint' },
    { column = 'name', type = 'text' },
    { column = 'place', type = 'text' },
    { column = 'tags', type = 'jsonb' },
    { column = 'way', type = 'point', projection = 4326, not_null = true },
})

function osm2pgsql.process_node(object)
    if object.tags.place then
        tables.point:insert({
            osm_id = object.id,
            name = object.tags.name,
            place = object.tags.place,
            tags = object.tags,
            way = object:as_point(),
        })
    end
end

function osm2pgsql.process_relation(object)
    if object.tags.type == 'boundary'
       and object.tags.boundary == 'administrative' then
        tables.polygon:insert({
            osm_id = object.id,
            name = object.tags.name,
            admin_level = object.tags.admin_level,
            boundary = object.tags.boundary,
            tags = object.tags,
            way = object:as_multipolygon(),
        })
    end
end
