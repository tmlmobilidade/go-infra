#!/usr/bin/env bash

set -euo pipefail

# # #
# Weekly Europe OSM refresh for LocationsDB.
# Cron: Sunday 04:00 Europe/Lisbon → /opt/app/update.log
#
# Steps: lock → fetch new PBF → FORCE_IMPORT full osm2pgsql + geojson.
# Keeps PostGIS data dir; --create in osm2pgsql rebuilds pois tables.

APP_DIR="/opt/app"
PBF_DIR="/opt/app/persistent-data/osm/pbf"
PBF="$PBF_DIR/europe-latest.osm.pbf"
LOCK="/var/lock/locationsdb-osm-update.lock"
LOG_TAG="[locationsdb-update]"

exec 9>"$LOCK"
if ! flock -n 9; then
	echo "$LOG_TAG Already running (lock $LOCK). Exit."
	exit 0
fi

cd "$APP_DIR"

echo ""
echo "============================================================"
echo "$LOG_TAG Starting at $(date -Is)"
echo "============================================================"

mkdir -p "$PBF_DIR" /opt/app/persistent-data/osm/geojson/backups

# Backup previous GeoJSON if present
if [[ -f /opt/app/persistent-data/osm/geojson/pois.geojson ]]; then
	BACKUP="/opt/app/persistent-data/osm/geojson/backups/pois.geojson.$(date +%Y%m%d-%H%M%S)"
	echo "$LOG_TAG Backing up GeoJSON → $BACKUP"
	cp /opt/app/persistent-data/osm/geojson/pois.geojson "$BACKUP"
	# Keep last 4 backups
	ls -1t /opt/app/persistent-data/osm/geojson/backups/pois.geojson.* 2>/dev/null | tail -n +5 | xargs -r rm -f
fi

# Force fresh Geofabrik extract (osm-download skips if file exists)
if [[ -f "$PBF" ]]; then
	echo "$LOG_TAG Removing old PBF to force re-download..."
	rm -f "$PBF" "$PBF.tmp"
fi

echo "$LOG_TAG Running FORCE_IMPORT import-osm.sh ..."
FORCE_IMPORT=1 /opt/app/import-osm.sh

echo "$LOG_TAG Finished at $(date -Is)"
