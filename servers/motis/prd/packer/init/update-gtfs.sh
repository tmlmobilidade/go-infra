#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/app"
BASE_DIR="$APP_DIR/persistent-data"
INPUT_DIR="$BASE_DIR/input"
GTFS_DIR="$INPUT_DIR/gtfs"
GTFS_PATH="$GTFS_DIR/GTFS.zip"

GTFS_URL="${GTFS_URL:-https://go.tmlmobilidade.pt/hub/api/v1/plans/gtfs}"

cd "$APP_DIR"

echo ""
echo "============================================================"
echo "[motis-gtfs-update] Starting at $(date -Is)"
echo "============================================================"

mkdir -p "$GTFS_DIR" "$BASE_DIR/data"

# Ensure MOTIS can write to its data directory.
chown -R 100:100 "$BASE_DIR/data"
chmod -R 775 "$BASE_DIR/data"
chmod -R a+rX "$INPUT_DIR"

echo "[motis-gtfs-update] Downloading GTFS ..."
wget -q --show-progress -O "$GTFS_PATH.new" "$GTFS_URL"
test -s "$GTFS_PATH.new"
mv "$GTFS_PATH.new" "$GTFS_PATH"

chmod -R a+rX "$INPUT_DIR"

echo "[motis-gtfs-update] Running motis-import ..."
docker compose --profile tools run --rm motis-import

# Re-assert ownership after import.
chown -R 100:100 "$BASE_DIR/data"

echo "[motis-gtfs-update] Recreating motis-server ..."
docker compose up -d --force-recreate motis-server

echo "[motis-gtfs-update] Finished at $(date -Is)"