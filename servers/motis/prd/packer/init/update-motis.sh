#!/usr/bin/env bash
set -euo pipefail

# Refresh GTFS (+ optional OSM), re-import, recreate server.
# Cron: 0 4 * * * ubuntu /opt/app/update-motis.sh >> /opt/app/update.log 2>&1

APP_DIR="/opt/app"
BASE_DIR="$APP_DIR/persistent-data"
INPUT_DIR="$BASE_DIR/input"
OSM_PATH="$INPUT_DIR/osm.pbf"
GTFS_PATH="$INPUT_DIR/gtfs/GTFS.zip"

OSM_URL="${OSM_URL:-https://download.geofabrik.de/europe/portugal-latest.osm.pbf}"
GTFS_URL="${GTFS_URL:-https://go.tmlmobilidade.pt/hub/api/v1/plans/gtfs}"
REFRESH_OSM="${REFRESH_OSM:-1}"

cd "$APP_DIR"

echo ""
echo "============================================================"
echo "[motis-update] Starting update at $(date -Is)"
echo "============================================================"

mkdir -p "$INPUT_DIR/gtfs" "$BASE_DIR/data"

# Image USER motis = Alpine UID 100
chown -R 100:100 "$BASE_DIR/data"
chmod -R 775 "$BASE_DIR/data"
chmod -R a+rX "$INPUT_DIR"

if [[ "$REFRESH_OSM" == "1" ]]; then
	echo "[motis-update] Downloading OSM ..."
	wget -q --show-progress -O "$OSM_PATH.new" "$OSM_URL"
	test -s "$OSM_PATH.new"
	mv "$OSM_PATH.new" "$OSM_PATH"
fi

echo "[motis-update] Downloading GTFS ..."
wget -q --show-progress -O "$GTFS_PATH.new" "$GTFS_URL"
test -s "$GTFS_PATH.new"
mv "$GTFS_PATH.new" "$GTFS_PATH"
chmod -R a+rX "$INPUT_DIR"

echo "[motis-update] Running motis-import ..."
docker compose --profile tools run --rm motis-import

# Re-assert ownership after import
chown -R 100:100 "$BASE_DIR/data"

echo "[motis-update] Recreating motis-server ..."
docker compose up -d --force-recreate motis-server

echo "[motis-update] Finished at $(date -Is)"
