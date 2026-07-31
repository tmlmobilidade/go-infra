#!/usr/bin/env bash

set -euo pipefail

# # #
# SETTINGS

# Persistent volume mounted by attach-volume.sh.
BASE_DIR="/opt/app/persistent-data"
CUSTOM_FILES="$BASE_DIR/custom_files"
PBF_URL="${PBF_URL:-https://download.geofabrik.de/europe/portugal-latest.osm.pbf}"
PBF_PATH="$CUSTOM_FILES/portugal-latest.osm.pbf"

# valhalla-scripted image runs as user `valhalla` (UID/GID 1000).
VALHALLA_UID=1000
VALHALLA_GID=1000


# 1.
# Create custom_files (+ backups) for PBF, tiles, tar.
mkdir -p "$CUSTOM_FILES/backups"

# 2.
# Bind-mount over /custom_files hides image-baked PBF.
# Download once onto the volume if missing.

if [[ -s "$PBF_PATH" ]]; then
	echo "[setup-valhalla] PBF already present at $PBF_PATH"
else
	echo "[setup-valhalla] Downloading Portugal PBF from $PBF_URL ..."
	wget -q -O "$PBF_PATH" "$PBF_URL"
	test -s "$PBF_PATH"
	echo "[setup-valhalla] PBF download complete."
fi


# 3.
# Ownership for the container user.

chown -R "$VALHALLA_UID:$VALHALLA_GID" "$CUSTOM_FILES"
chmod -R 775 "$CUSTOM_FILES"

echo "[setup-valhalla] Setup complete under $CUSTOM_FILES"
