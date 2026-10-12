#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/app"
BASE_DIR="$APP_DIR/persistent-data"
INPUT_DIR="$BASE_DIR/input"
OSM_PATH="$INPUT_DIR/osm.pbf"

OSM_URL="${OSM_URL:-https://download.geofabrik.de/europe/portugal-latest.osm.pbf}"

cd "$APP_DIR"

echo ""
echo "============================================================"
echo "[motis-osm-update] Starting at $(date -Is)"
echo "============================================================"

mkdir -p "$INPUT_DIR" "$BASE_DIR/data"

# Ensure MOTIS can write to its data directory.
chown -R 100:100 "$BASE_DIR/data"
chmod -R 775 "$BASE_DIR/data"
chmod -R a+rX "$INPUT_DIR"

echo "[motis-osm-update] Downloading OSM ..."
wget -q --show-progress -O "$OSM_PATH.new" "$OSM_URL"
test -s "$OSM_PATH.new"
mv "$OSM_PATH.new" "$OSM_PATH"

chmod -R a+rX "$INPUT_DIR"

echo "[motis-osm-update] Running motis-import ..."
docker compose --profile tools run --rm motis-import

# Re-assert ownership after import.
chown -R 100:100 "$BASE_DIR/data"

echo "[motis-osm-update] Recreating motis-server ..."
docker compose up -d --force-recreate motis-server

echo "[motis-osm-update] Finished at $(date -Is)"