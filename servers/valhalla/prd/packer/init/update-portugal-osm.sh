#!/usr/bin/env bash
set -euo pipefail

# Daily Portugal OSM refresh for Valhalla.
# Layout (Packer/OCI):
#   /opt/app/compose.yaml
#   /opt/app/update-portugal-osm.sh
#   /opt/app/update.log
#   /opt/app/persistent-data/custom_files/{pbf,tiles,tar,backups}

VALHALLA_DIR="/opt/app"
CUSTOM_DIR="$VALHALLA_DIR/persistent-data/custom_files"
PBF_NAME="portugal-latest.osm.pbf"
PBF_URL="https://download.geofabrik.de/europe/portugal-latest.osm.pbf"

cd "$VALHALLA_DIR"

echo ""
echo "============================================================"
echo "[valhalla-update] Starting update at $(date -Is)"
echo "============================================================"

mkdir -p "$CUSTOM_DIR/backups"

echo "[valhalla-update] Downloading latest Portugal OSM extract..."

wget -q --show-progress -O "$CUSTOM_DIR/$PBF_NAME.new" "$PBF_URL"

if [ ! -s "$CUSTOM_DIR/$PBF_NAME.new" ]; then
  echo "[valhalla-update] ERROR: Downloaded file is empty. Aborting."
  rm -f "$CUSTOM_DIR/$PBF_NAME.new"
  exit 1
fi

echo "[valhalla-update] Download complete."

if [ -f "$CUSTOM_DIR/$PBF_NAME" ]; then
  BACKUP_FILE="$CUSTOM_DIR/backups/$PBF_NAME.$(date +%Y%m%d-%H%M%S)"
  echo "[valhalla-update] Backing up previous PBF to $BACKUP_FILE"
  cp "$CUSTOM_DIR/$PBF_NAME" "$BACKUP_FILE"
fi

echo "[valhalla-update] Replacing PBF atomically..."
mv "$CUSTOM_DIR/$PBF_NAME.new" "$CUSTOM_DIR/$PBF_NAME"

echo "[valhalla-update] Removing old Valhalla tiles to force rebuild..."
rm -rf "$CUSTOM_DIR/valhalla_tiles"
rm -f "$CUSTOM_DIR/valhalla_tiles.tar"

# Keep ownership for container user after host-side writes.
chown -R 1000:1000 "$CUSTOM_DIR" || true

echo "[valhalla-update] Recreating Valhalla container..."
docker compose up -d --force-recreate valhalla

echo "[valhalla-update] Waiting for Valhalla to start..."
sleep 20

echo "[valhalla-update] Testing Valhalla route endpoint..."

if curl -fsS -G "http://127.0.0.1:8002/route" \
  --data-urlencode 'json={
    "locations": [
      { "lat": 38.7223, "lon": -9.1393 },
      { "lat": 38.7369, "lon": -9.1427 }
    ],
    "costing": "bus",
    "directions_options": { "units": "kilometers" }
  }' > /tmp/valhalla-test-response.json; then

  echo "[valhalla-update] Health check succeeded."

else
  echo "[valhalla-update] WARNING: Health check failed (tile rebuild may still be running)."
  echo "[valhalla-update] Check logs with: docker logs valhalla"
fi

echo "[valhalla-update] Finished at $(date -Is)"
