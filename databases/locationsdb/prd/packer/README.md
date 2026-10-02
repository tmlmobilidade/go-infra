# Building custom images with Packer

Follow this guide to build custom VM images using Packer on OCI. You will need access to an OCI compartment and the OCI-CLI tool configured in your machine.


## Usage
Open a new terminal window and change the shell into this directory:
```
cd ./infra/locationsdb/packer
```

Initialize the packer module and validate the configuration files:
```
packer init .
packer validate .
packer build .
```

## Post-import location tree

`import-osm.sh` runs `sql/**02-indexes**.sql` (indexes and statistics) then
`sql/03-cache.sql` (cache schema, tree build, and publish) after OSM data is loaded. The same steps run
on reused volumes without reimporting OSM. Only `01-postgis.sql` belongs to the
PostgreSQL entrypoint; the other files require the imported tables.

The SQL builder supports ES (2 → 4 → 6 → 8) and PT (2 → 6|4 → 7 → 8), using
bounding-box centers or the nearest polygon vertex for parent matching. It attaches
to the nearest available ancestor slot, includes boundary points, and keeps names
in ICU English order. Geometry never leaves PostgreSQL. The SQL slot mapping must
stay aligned with GO's `packages-new/providers/locations/src/levels.ts`.

The published `cache` row (`locations-administrative-tree`) contains the
JSON `cache_value` consumed by GO (today an array of country roots). Publication and dataset readiness commit
atomically. A failed import/build leaves the previous tree available; a missing
country or administrative slot prevents publication. Temporary build tables are
dropped on commit. GO reads this cache with a 60-second process TTL and has no
builder or refresh worker.

To install the schema and rebuild after a completed import on an existing VM:

```sh
cd /opt/app
docker compose exec -T postgis psql -U osm -d osm -v ON_ERROR_STOP=1 < sql/02-indexes.sql
docker compose exec -T postgis psql -U osm -d osm -v ON_ERROR_STOP=1 < sql/cache.sql
```

Do not run `02-indexes.sql` inside a transaction: it creates indexes
concurrently. `cache.sql` manages its own transaction. After a build failure,
fix the cause and rerun `cache.sql`; an OSM reimport is unnecessary if its tables
are complete. Every successful rebuild advances `locations_dataset.generation`.
