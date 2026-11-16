#!/bin/bash
# OSM World download + validate, then rotate mbtiles and recreate planetiler.
# Intended for Saturday cron, e.g.:
#   0 4 * * 6 root /opt/app/map-update.sh
set -eu

LOG_DIR=/opt/app/persistent-data/logs
DATA_DIR=/opt/app/persistent-data/planetiler-data
TILESERVER_DIR=/opt/app/persistent-data/tileserver
COMPOSE_FILE=/opt/app/compose.yaml

PBF_NAME=planet-latest.osm.pbf
PBF_URL="${PBF_URL:-https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf}"
PBF_PATH="$DATA_DIR/$PBF_NAME"
PBF_STAGING="$DATA_DIR/$PBF_NAME.new"
LAST_GOOD="$DATA_DIR/last-good-pbf.stats"
OSMIUM_IMAGE="${OSMIUM_IMAGE:-iboates/osmium:2}"
MIN_PBF_BYTES="${MIN_PBF_BYTES:-50000000000}"

mkdir -p "$LOG_DIR" "$DATA_DIR" "$TILESERVER_DIR"

log() {
	echo "[maps-updater $(date -Is)] $*"
}

run_osmium() {
	docker run --rm -v "$DATA_DIR:/data:ro" "$OSMIUM_IMAGE" "$@"
}

# Returns first integer found on a line matching the pattern.
line_int() {
	awk -v pat="$1" '
		tolower($0) ~ tolower(pat) {
			for (i = 1; i <= NF; i++) {
				gsub(/[^0-9]/, "", $i)
				if ($i != "") { print $i; exit }
			}
		}
	'
}

validate_pbf() {
	local pbf_basename="$1"
	local pbf_host="$DATA_DIR/$pbf_basename"
	local info size nodes ways relations
	local prev_size prev_nodes prev_ways prev_relations

	if [ ! -s "$pbf_host" ]; then
		log "ERROR: PBF missing or empty: $pbf_host"
		return 1
	fi

	size=$(wc -c < "$pbf_host" | tr -d ' ')
	log "PBF size: $size bytes"
	if [ "$size" -lt "$MIN_PBF_BYTES" ]; then
		log "ERROR: PBF too small ($size < $MIN_PBF_BYTES); incomplete download?"
		return 1
	fi

	# -e reads the whole file → catches truncated/corrupt PBFs.
	if ! info=$(run_osmium fileinfo -e "/data/$pbf_basename"); then
		log "ERROR: osmium fileinfo failed — corrupt or unreadable PBF."
		return 1
	fi

	nodes=$(printf '%s\n' "$info" | line_int nodes)
	ways=$(printf '%s\n' "$info" | line_int ways)
	relations=$(printf '%s\n' "$info" | line_int relations)
	log "OSM counts: nodes=${nodes:-?} ways=${ways:-?} relations=${relations:-?}"

	if [ -z "${nodes:-}" ] || [ -z "${ways:-}" ] || [ -z "${relations:-}" ] \
		|| [ "$nodes" -le 0 ] || [ "$ways" -le 0 ] || [ "$relations" -le 0 ]; then
		log "ERROR: bad element counts."
		return 1
	fi

	# Header bbox should look like a world extract.
	if ! printf '%s\n' "$info" | grep -E '(-180|-179)' | grep -qE '(180|179)'; then
		log "ERROR: bbox does not look like a World planet extract."
		return 1
	fi

	# Compare to last good download (size/counts must not drop a lot).
	if [ -f "$LAST_GOOD" ]; then
		read -r prev_size prev_nodes prev_ways prev_relations < "$LAST_GOOD" || true
		if [ "${prev_size:-0}" -gt 0 ] && [ "$size" -lt $((prev_size * 90 / 100)) ]; then
			log "ERROR: size dropped too much ($size vs previous $prev_size)."
			return 1
		fi
		if [ "${prev_nodes:-0}" -gt 0 ] && [ "$nodes" -lt $((prev_nodes * 95 / 100)) ]; then
			log "ERROR: node count dropped too much ($nodes vs previous $prev_nodes)."
			return 1
		fi
		if [ "${prev_ways:-0}" -gt 0 ] && [ "$ways" -lt $((prev_ways * 95 / 100)) ]; then
			log "ERROR: way count dropped too much ($ways vs previous $prev_ways)."
			return 1
		fi
		if [ "${prev_relations:-0}" -gt 0 ] && [ "$relations" -lt $((prev_relations * 95 / 100)) ]; then
			log "ERROR: relation count dropped too much ($relations vs previous $prev_relations)."
			return 1
		fi
		log "OK vs last good: $prev_size $prev_nodes $prev_ways $prev_relations"
	fi

	VALIDATE_SIZE="$size"
	VALIDATE_NODES="$nodes"
	VALIDATE_WAYS="$ways"
	VALIDATE_RELATIONS="$relations"
	return 0
}

download_planet() {
	log "Downloading $PBF_URL ..."
	rm -f "$PBF_STAGING"
	if ! wget -c --progress=dot:giga -O "$PBF_STAGING" "$PBF_URL"; then
		log "ERROR: wget failed."
		rm -f "$PBF_STAGING"
		return 1
	fi
	[ -s "$PBF_STAGING" ] || { log "ERROR: empty download."; rm -f "$PBF_STAGING"; return 1; }
	log "Download finished."
}

promote_mbtiles() {
	if [ -f "$TILESERVER_DIR/next.mbtiles" ]; then
		if [ -f "$TILESERVER_DIR/current.mbtiles" ]; then
			rm -f "$TILESERVER_DIR/previous.mbtiles"
			mv "$TILESERVER_DIR/current.mbtiles" "$TILESERVER_DIR/previous.mbtiles"
		fi
		mv "$TILESERVER_DIR/next.mbtiles" "$TILESERVER_DIR/current.mbtiles"
	fi
	log "Mbtiles rotation done."
}

recreate_stack() {
	log "Recreating planetiler / tileserver / nginx..."
	docker compose -f "$COMPOSE_FILE" up -d --build --force-recreate --remove-orphans --pull=always \
		planetiler tileserver nginx
	log "Stack recreated."
}

LOG_FILE="$LOG_DIR/planetiler-$(date +%Y-%m-%d).log"
exec >>"$LOG_FILE" 2>&1

log "=== maps-updater start ==="

download_planet || exit 1

VALIDATE_SIZE=0
VALIDATE_NODES=0
VALIDATE_WAYS=0
VALIDATE_RELATIONS=0

if ! validate_pbf "$(basename "$PBF_STAGING")"; then
	rm -f "$PBF_STAGING"
	exit 1
fi

mv -f "$PBF_STAGING" "$PBF_PATH"
echo "$VALIDATE_SIZE $VALIDATE_NODES $VALIDATE_WAYS $VALIDATE_RELATIONS" > "$LAST_GOOD"
log "Promoted PBF and saved last-good stats."

promote_mbtiles
recreate_stack

log "=== maps-updater complete ==="
