#!/usr/bin/env bash

set -euo pipefail

# # #
# SETTINGS

# Persistent block volume mounted by attach-volume.sh.
BASE_DIR="/opt/app/persistent-data"
ENV_FILE="/opt/app/secrets/.env"
COMPOSE_DIR="/opt/app"


# 1.
# Create directory layout used by compose.yaml:
#   osm/postgres — PostGIS data
#   osm/pbf      — Geofabrik Europe extract
#   osm/flatnodes — osm2pgsql flat-nodes file
#   osm/geojson  — exported FeatureCollection
#
# beginor/postgis (postgres) runs as UID/GID 999.

mkdir -p \
	"$BASE_DIR/osm/postgres" \
	"$BASE_DIR/osm/pbf" \
	"$BASE_DIR/osm/flatnodes" \
	"$BASE_DIR/osm/geojson"

chown -R 999:999 "$BASE_DIR/osm/postgres"
chmod -R 700 "$BASE_DIR/osm/postgres"

chown -R ubuntu:ubuntu \
	"$BASE_DIR/osm/pbf" \
	"$BASE_DIR/osm/flatnodes" \
	"$BASE_DIR/osm/geojson" || true
chmod -R 755 \
	"$BASE_DIR/osm/pbf" \
	"$BASE_DIR/osm/flatnodes" \
	"$BASE_DIR/osm/geojson"

echo "[setup-postgres] Directories ready under $BASE_DIR/osm"


# 2.
# Start PostGIS and sync role password from secrets/.env.
# POSTGRES_PASSWORD in compose env only applies on first empty datadir;
# reused block volumes keep the old password — ALTER via local socket (trust).

cd "$COMPOSE_DIR"

source "$ENV_FILE"

docker compose up -d postgis

echo "[setup-postgres] Waiting for PostGIS..."

until docker compose exec -T postgis \
    pg_isready -U "${POSTGRES_USER:-osm}" -d "${POSTGRES_DB:-osm}" >/dev/null 2>&1
do
    sleep 2
done

docker compose exec -T postgis \
    psql -U "${POSTGRES_USER:-osm}" -d "${POSTGRES_DB:-osm}" \
    -c "ALTER USER ${POSTGRES_USER:-osm} WITH PASSWORD '${POSTGRES_PASSWORD}';"

echo "[setup-postgres] PostgreSQL password synced."