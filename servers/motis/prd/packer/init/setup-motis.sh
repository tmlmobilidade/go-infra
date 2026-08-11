#!/usr/bin/env bash

set -euo pipefail

# Prepare MOTIS input layout on the block volume (README layout).
#   /opt/app/persistent-data/input/osm.pbf
#   /opt/app/persistent-data/input/gtfs/GTFS.zip
#   /opt/app/persistent-data/data/

BASE_DIR="/opt/app/persistent-data"
INPUT_DIR="$BASE_DIR/input"
DATA_DIR="$BASE_DIR/data"
OSM_PATH="$INPUT_DIR/osm.pbf"
GTFS_PATH="$INPUT_DIR/gtfs/GTFS.zip"

OSM_URL="${OSM_URL:-https://download.geofabrik.de/europe/portugal-latest.osm.pbf}"
GTFS_URL="${GTFS_URL:-https://go.tmlmobilidade.pt/hub/api/v1/plans/gtfs}"

mkdir -p "$INPUT_DIR/gtfs" "$DATA_DIR"

# Image runs as USER motis (Alpine adduser -S → UID/GID 100).
# Without this, import cannot write /data → empty data → nigiri_bin_ver fail.
MOTIS_UID="${MOTIS_UID:-100}"
MOTIS_GID="${MOTIS_GID:-100}"

# 1. OSM extract (Portugal) — download once if missing
if [[ -s "$OSM_PATH" ]]; then
	echo "[setup-motis] OSM already present at $OSM_PATH"
else
	echo "[setup-motis] Downloading OSM from $OSM_URL ..."
	wget -q --show-progress -O "$OSM_PATH" "$OSM_URL"
	test -s "$OSM_PATH"
	echo "[setup-motis] OSM download complete."
fi

# 2. GTFS static — always refresh on first boot / setup
echo "[setup-motis] Fetching GTFS from $GTFS_URL ..."
wget -q --show-progress -O "$GTFS_PATH" "$GTFS_URL"
test -s "$GTFS_PATH"
echo "[setup-motis] GTFS download complete."

chmod -R a+rX "$INPUT_DIR"
chown -R "$MOTIS_UID:$MOTIS_GID" "$DATA_DIR"
chmod -R 775 "$DATA_DIR"

echo "[setup-motis] Setup complete under $BASE_DIR (data owned ${MOTIS_UID}:${MOTIS_GID})"
