#!/usr/bin/env bash
set -euo pipefail

# ── Source MongoDB ───────────────────────────────────────────────────────────
SOURCE_DB_HOST=""
SOURCE_DB_PORT=""
SOURCE_DB_USERNAME=""
SOURCE_DB_PASSWORD=""
SOURCE_DB_AUTH_DATABASE="admin"

# Optional: source over SSH tunnel
SOURCE_TUNNEL_ENABLED=""
SOURCE_TUNNEL_LOCAL_PORT=""
SOURCE_TUNNEL_SSH_HOST=""
SOURCE_TUNNEL_SSH_USERNAME=""
SOURCE_TUNNEL_SSH_KEY_PATH="/"

# ── Destination MongoDB ──────────────────────────────────────────────────────
DESTINATION_DB_HOST=""
DESTINATION_DB_PORT=""
DESTINATION_DB_USERNAME=""
DESTINATION_DB_PASSWORD=""
DESTINATION_DB_AUTH_DATABASE="admin"

# Optional: destination over SSH tunnel
DESTINATION_TUNNEL_ENABLED=""
DESTINATION_TUNNEL_LOCAL_PORT=""
DESTINATION_TUNNEL_SSH_HOST=""
DESTINATION_TUNNEL_SSH_USERNAME=""
DESTINATION_TUNNEL_SSH_KEY_PATH="/"

# ── Sync options ─────────────────────────────────────────────────────────────
# Format:
#   db.collection                  — copy as-is
#   srcDb.srcColl:destDb.destColl  — remap namespace
# Empty = copy all databases as-is.
COLLECTIONS=(
  # "core.users"
  # "core.attachments"
  # "operation.rides"
  # "operations.hashed-trips"
)

# Comma-separated db.collection; applied when COLLECTIONS is empty.
EXCLUDED_COLLECTIONS=""

# Skipped when COLLECTIONS is empty (full sync).
SYSTEM_DATABASES=(admin config local)

# replace     — drop destination collections, then restore (default)
# incremental — insert missing docs only; existing _id values are skipped (no drop)
#               (mongorestore cannot upsert/update; use replace if you need a full refresh)
SYNC_MODE=replace

# ── Helpers ──────────────────────────────────────────────────────────────────

SSH_PIDS=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [--env FILE] [--incremental|--replace]

  --env FILE      Load variables from FILE (overrides script defaults)
  --incremental   Insert missing docs only; skip existing _id (no drop)
  --replace       Drop destination collections, then restore (default)
  -h, --help      Show this help
EOF
}

# Source a dotenv/bash file so its assignments override script defaults.
load_env_file() {
  local file=$1
  if [ ! -f "$file" ]; then
    echo "ERROR: env file not found: $file" >&2
    exit 1
  fi
  echo "Loading env from $file ..."
  set -a
  # shellcheck disable=SC1090
  source "$file"
  set +a
}

# Turn a comma-separated string (or single-element array) into a bash array.
# Allows COLLECTIONS=a,b or COLLECTIONS=(a b) in --env files.
normalize_array_var() {
  local name=$1
  local raw=""
  local -a current=()
  local item

  eval "current=(\"\${${name}[@]}\")"

  if declare -p "$name" 2>/dev/null | grep -q 'declare -a'; then
    if [ ${#current[@]} -eq 1 ] && [[ "${current[0]}" == *,* ]]; then
      raw="${current[0]}"
    else
      return 0
    fi
  else
    eval "raw=\"\${${name}-}\""
  fi

  eval "${name}=()"
  # strip spaces-only
  [ -z "${raw// /}" ] && return 0

  local IFS=,
  for item in $raw; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    [ -n "$item" ] && eval "${name}+=(\"\$item\")"
  done
}

cleanup() {
  for pid in "${SSH_PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

open_ssh_tunnel() {
  local label=$1
  local db_host=$2
  local db_port=$3
  local ssh_host=$4
  local ssh_user=$5
  local ssh_key=$6
  local local_port=$7

  echo "Opening $label SSH tunnel via $ssh_user@$ssh_host (localhost:$local_port → $db_host:$db_port) ..."

  ssh -i "$ssh_key" \
    -L "$local_port:$db_host:$db_port" \
    -N \
    -o ExitOnForwardFailure=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    "$ssh_user@$ssh_host" &
  SSH_PIDS+=($!)

  sleep 2
  if ! kill -0 "${SSH_PIDS[-1]}" 2>/dev/null; then
    echo "ERROR: $label SSH tunnel failed to establish" >&2
    exit 1
  fi
}

build_source_uri() {
  if [ "$SOURCE_TUNNEL_ENABLED" = true ]; then
    open_ssh_tunnel "source" \
      "$SOURCE_DB_HOST" "$SOURCE_DB_PORT" \
      "$SOURCE_TUNNEL_SSH_HOST" "$SOURCE_TUNNEL_SSH_USERNAME" "$SOURCE_TUNNEL_SSH_KEY_PATH" \
      "$SOURCE_TUNNEL_LOCAL_PORT"
    SOURCE_URI="mongodb://$SOURCE_DB_USERNAME:$SOURCE_DB_PASSWORD@localhost:$SOURCE_TUNNEL_LOCAL_PORT/?authSource=$SOURCE_DB_AUTH_DATABASE&directConnection=true"
  else
    SOURCE_URI="mongodb://$SOURCE_DB_USERNAME:$SOURCE_DB_PASSWORD@$SOURCE_DB_HOST:$SOURCE_DB_PORT/?authSource=$SOURCE_DB_AUTH_DATABASE&directConnection=true"
  fi
}

build_destination_uri() {
  if [ "$DESTINATION_TUNNEL_ENABLED" = true ]; then
    open_ssh_tunnel "destination" \
      "$DESTINATION_DB_HOST" "$DESTINATION_DB_PORT" \
      "$DESTINATION_TUNNEL_SSH_HOST" "$DESTINATION_TUNNEL_SSH_USERNAME" "$DESTINATION_TUNNEL_SSH_KEY_PATH" \
      "$DESTINATION_TUNNEL_LOCAL_PORT"
    DESTINATION_URI="mongodb://$DESTINATION_DB_USERNAME:$DESTINATION_DB_PASSWORD@localhost:$DESTINATION_TUNNEL_LOCAL_PORT/?authSource=$DESTINATION_DB_AUTH_DATABASE&directConnection=true"
  else
    DESTINATION_URI="mongodb://$DESTINATION_DB_USERNAME:$DESTINATION_DB_PASSWORD@$DESTINATION_DB_HOST:$DESTINATION_DB_PORT/?authSource=$DESTINATION_DB_AUTH_DATABASE&directConnection=true"
  fi
}

# Append mode-specific mongorestore flags to the named array.
# mongorestore only inserts; it never updates. Without --drop, docs whose _id
# already exists on the destination are skipped (E11000 / duplicate key).
append_restore_mode_args() {
  local -a _args_ref
  eval "_args_ref=(\"\${${1}[@]}\")"

  case "$SYNC_MODE" in
    replace)
      _args_ref+=(--drop)
      ;;
    incremental)
      # No extra flags: default mongorestore inserts missing docs and skips
      # existing _id values. (--mode is a mongoimport option, not mongorestore.)
      ;;
    *)
      echo "ERROR: invalid SYNC_MODE '$SYNC_MODE' (expected replace or incremental)" >&2
      exit 1
      ;;
  esac

  eval "${1}=(\"\${_args_ref[@]}\")"
}

# Copy one namespace. Args: src_db src_coll dest_db dest_coll
copy_collection() {
  local src_db=$1
  local src_coll=$2
  local dest_db=$3
  local dest_coll=$4

  echo "  $src_db.$src_coll → $dest_db.$dest_coll ($SYNC_MODE)"

  local restore_args=(
    --uri="$DESTINATION_URI"
    --archive
    --gzip
    --nsInclude="$src_db.$src_coll"
    --numInsertionWorkersPerCollection=16
  )
  append_restore_mode_args restore_args

  if [ "$src_db" != "$dest_db" ] || [ "$src_coll" != "$dest_coll" ]; then
    restore_args+=(--nsFrom="$src_db.$src_coll" --nsTo="$dest_db.$dest_coll")
  fi

  mongodump \
    --uri="$SOURCE_URI" \
    --db="$src_db" \
    --collection="$src_coll" \
    --archive \
    --gzip \
  | mongorestore "${restore_args[@]}"
}

# Copy all databases, keeping names as-is.
copy_all_as_is() {
  local restore_args=(
    --uri="$DESTINATION_URI"
    --archive
    --gzip
    --numInsertionWorkersPerCollection=16
  )
  append_restore_mode_args restore_args

  local excluded=()
  for db in "${SYSTEM_DATABASES[@]}"; do
    restore_args+=(--nsExclude="$db.*")
    excluded+=("$db.*")
  done

  if [ -n "$EXCLUDED_COLLECTIONS" ]; then
    local IFS=,
    for name in $EXCLUDED_COLLECTIONS; do
      name="${name// /}"
      if [ -n "$name" ]; then
        restore_args+=(--nsExclude="$name")
        excluded+=("$name")
      fi
    done
  fi

  local exclude_msg=""
  if [ ${#excluded[@]} -gt 0 ]; then
    local IFS=,
    exclude_msg=", excluding: ${excluded[*]}"
  fi
  echo "  *.* → *.* (as-is, $SYNC_MODE${exclude_msg})"

  mongodump \
    --uri="$SOURCE_URI" \
    --archive \
    --gzip \
  | mongorestore "${restore_args[@]}"
}

parse_mapping() {
  # Sets SRC_DB SRC_COLL DEST_DB DEST_COLL from a mapping string.
  local mapping=$1
  local src dest

  if [[ "$mapping" == *:* ]]; then
    src="${mapping%%:*}"
    dest="${mapping#*:}"
  else
    src="$mapping"
    dest="$mapping"
  fi

  if [[ ! "$src" =~ ^[^.]+[.].+$ ]] || [[ ! "$dest" =~ ^[^.]+[.].+$ ]]; then
    echo "ERROR: invalid mapping '$mapping' (expected db.collection or srcDb.coll:destDb.coll)" >&2
    exit 1
  fi

  SRC_DB="${src%%.*}"
  SRC_COLL="${src#*.}"
  DEST_DB="${dest%%.*}"
  DEST_COLL="${dest#*.}"
}

run_migration() {
  if [ ${#COLLECTIONS[@]} -eq 0 ]; then
    echo "Starting migration: all databases (as-is, $SYNC_MODE) ..."
    copy_all_as_is
  else
    echo "Starting migration (${#COLLECTIONS[@]} collection(s), $SYNC_MODE) ..."

    for mapping in "${COLLECTIONS[@]}"; do
      mapping="${mapping// /}"
      [ -z "$mapping" ] && continue
      parse_mapping "$mapping"
      copy_collection "$SRC_DB" "$SRC_COLL" "$DEST_DB" "$DEST_COLL"
    done
  fi

  echo "Migration complete."
}

# ── Main ─────────────────────────────────────────────────────────────────────

ENV_FILE=""
CLI_SYNC_MODE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --env)
      [ $# -ge 2 ] || { echo "ERROR: --env requires a file path" >&2; exit 1; }
      ENV_FILE=$2
      shift 2
      ;;
    --env=*)
      ENV_FILE="${1#--env=}"
      shift
      ;;
    --incremental)
      CLI_SYNC_MODE=incremental
      shift
      ;;
    --replace)
      CLI_SYNC_MODE=replace
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -n "$ENV_FILE" ]; then
  load_env_file "$ENV_FILE"
  normalize_array_var COLLECTIONS
  normalize_array_var SYSTEM_DATABASES
fi

# CLI mode flags always win over script defaults / --env.
if [ -n "$CLI_SYNC_MODE" ]; then
  SYNC_MODE=$CLI_SYNC_MODE
fi

build_source_uri
build_destination_uri
run_migration