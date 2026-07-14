#!/usr/bin/env bash

set -euo pipefail

CUSTOM_DIR="${CUSTOM_DIR}"
PBF="${PBF}"
URL="${URL}"
DEPLOY="${DEPLOY}"
NS="${NS}"

echo "=================================="
echo "Valhalla update started"
echo "=================================="

mkdir -p "$CUSTOM_DIR/backups"

curl -fsSL \
  "$URL" \
  -o "$CUSTOM_DIR/$PBF.new"

if [ ! -s "$CUSTOM_DIR/$PBF.new" ]; then
    echo "Download failed"
    exit 1
fi

if [ -f "$CUSTOM_DIR/$PBF" ]; then

    cp \
      "$CUSTOM_DIR/$PBF" \
      "$CUSTOM_DIR/backups/$PBF.$(date +%Y%m%d-%H%M%S)"
fi

mv \
  "$CUSTOM_DIR/$PBF.new" \
  "$CUSTOM_DIR/$PBF"

rm -rf \
  "$CUSTOM_DIR/valhalla_tiles"

rm -f \
  "$CUSTOM_DIR/valhalla_tiles.tar"

find "$CUSTOM_DIR/backups" \
  -type f \
  -mtime +14 \
  -delete

kubectl rollout restart deployment/$DEPLOY -n $NS

kubectl rollout status deployment/$DEPLOY \
    -n $NS \
    --timeout=45m