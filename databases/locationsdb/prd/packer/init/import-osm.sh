#!/usr/bin/env bash

set -euo pipefail

# # #
# One-shot Europe OSM → PostGIS → GeoJSON import.
# Safe to re-run: skips if marker exists unless FORCE_IMPORT=1.
# Needs large BV (recommend >= 500 GiB): ~33GB PBF + flat-nodes + PostGIS.
#
# IMPORTANT: do NOT use `docker compose up --abort-on-container-exit` here.
# osm-download exits 0 quickly → compose SIGKILLs osm2pgsql (exit 137).

APP_DIR="/opt/app"
MARKER="/opt/app/persistent-data/osm/.imported"
FLATNODES="/opt/app/persistent-data/osm/flatnodes"

cd "$APP_DIR"

if [[ -f "$MARKER" && "${FORCE_IMPORT:-0}" != "1" ]]; then
	echo "[import-osm] Already imported ($(cat "$MARKER")). Set FORCE_IMPORT=1 to redo."
	exit 0
fi

echo "[import-osm] Ensuring PostGIS is up..."
docker compose up -d postgis

echo "[import-osm] Waiting for PostGIS healthy..."
for i in $(seq 1 60); do
	if docker compose exec -T postgis pg_isready -U osm -d osm >/dev/null 2>&1; then
		break
	fi
	sleep 2
	if [[ "$i" -eq 60 ]]; then
		echo "[import-osm] ERROR: PostGIS not healthy" >&2
		exit 1
	fi
done

rm -f "$FLATNODES"/*.flat
mkdir -p "$FLATNODES"
chmod 777 "$FLATNODES"

if ! docker compose --profile import config 2>/dev/null | grep -q 'flat-nodes'; then
	echo "[import-osm] ERROR: rendered compose has no --flat-nodes. Fix /opt/app/compose.yaml" >&2
	exit 1
fi

echo "[import-osm] 1/3 download (skip if PBF exists)..."
docker compose --profile import run --rm osm-download

echo "[import-osm] 2/3 osm2pgsql (Europe — hours). Watch: ls -lh $FLATNODES/"
# --no-deps: postgis already up; do not re-run download (would confuse orchestration)
docker compose --profile import run --rm --no-deps osm2pgsql

if [[ ! -s "$FLATNODES/europe.flat" ]]; then
	echo "[import-osm] ERROR: europe.flat missing — flat-nodes not used. Abort before geojson." >&2
	exit 1
fi
ls -lh "$FLATNODES/europe.flat"

echo "[import-osm] 3/3 geojson export..."
docker compose --profile import run --rm --no-deps osm-geojson

date -Is > "$MARKER"
echo "[import-osm] Done. Marker: $MARKER"
echo "[import-osm] GeoJSON: /opt/app/persistent-data/osm/geojson/pois.geojson"
