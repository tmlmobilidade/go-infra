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

# Comma-separated collection names or db.collection globs; applied in every mode.
EXCLUDED_COLLECTIONS=""

# Skipped when COLLECTIONS is empty (full sync).
SYSTEM_DATABASES=(admin config local)

# replace     — drop destination collections, then restore (default)
# incremental — upsert every source document by _id without dropping collections.
#               Full scan; destination-only documents and existing indexes are retained.
SYNC_MODE=replace

# ── Helpers ──────────────────────────────────────────────────────────────────

SSH_PIDS=()
WORK_DIR=""
# Override these in --env if necessary.
SYNC_BATCH_SIZE=500
SYNC_MAX_ATTEMPTS=3
SYNC_RETRY_DELAY_MS=5000
SYNC_LOCK_FILE=/tmp/env-sync.lock
SOURCE_URI=""
DESTINATION_URI=""
SOURCE_DB_DIRECT_CONNECTION=false
DESTINATION_DB_DIRECT_CONNECTION=false
SOURCE_DB_REPLICA_SET=""
DESTINATION_DB_REPLICA_SET=""

# Print supported command-line options to stdout.
usage() {
  cat <<EOF
Usage: $(basename "$0") [--env FILE] [--incremental|--replace]

  --env FILE      Load variables from FILE (overrides script defaults)
  --incremental   Upsert source documents by _id (full scan, no drop)
  --replace       Drop destination collections, then restore (default)
  -h, --help      Show this help
EOF
}

# Args: trusted Bash/dotenv file path. Source and export its assignments,
# overriding script defaults; exit if the file does not exist.
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

# Args: variable name. Normalize its comma-separated value into a Bash array
# in place, preserving an existing array of separate entries.
normalize_array_var() {
  local name=$1
  local raw=""
  local -a current=()
  local item

  eval "current=(\"\${${name}[@]-}\")"

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
  return 0
}

# EXIT trap: stop recorded SSH processes and remove private temporary files.
# Ignore tunnel processes that have already exited.
cleanup() {
  for pid in "${SSH_PIDS[@]:-}"; do
    [ -n "$pid" ] || continue
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  [ -z "$WORK_DIR" ] || rm -rf "$WORK_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Args: label, database host/port, SSH host/user/key, local forwarding port.
# Start the SSH forward, record its PID for cleanup and check it remains alive.
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
  if ! kill -0 "${SSH_PIDS[${#SSH_PIDS[@]}-1]}" 2>/dev/null; then
    echo "ERROR: $label SSH tunnel failed to establish" >&2
    exit 1
  fi
}

# Args: SOURCE or DESTINATION prefix, setting suffix. Print the corresponding
# variable value for command substitution without evaluating its contents.
read_setting() {
  local name="${1}_${2}"
  printf '%s' "${!name}"
}

# Args: connection prefix, database host and port. Open a forward using
# the matching TUNNEL_* settings; its PID is recorded by open_ssh_tunnel.
open_configured_tunnel() {
  local prefix=$1 host=$2 port=$3
  open_ssh_tunnel "$prefix" "$host" "$port" \
    "$(read_setting "$prefix" TUNNEL_SSH_HOST)" \
    "$(read_setting "$prefix" TUNNEL_SSH_USERNAME)" \
    "$(read_setting "$prefix" TUNNEL_SSH_KEY_PATH)" \
    "$(read_setting "$prefix" TUNNEL_LOCAL_PORT)"
}

# Args: host, port, username, password, auth database, direct flag, replica set.
# Print a URI with percent-encoded credentials; pass secrets to mongosh via environment.
generate_uri() {
  local host=$1 port=$2 user=$3 password=$4 auth=$5 direct=$6 replica=$7
  ENV_SYNC_HOST="$host" ENV_SYNC_PORT="$port" ENV_SYNC_USER="$user" \
    ENV_SYNC_PASSWORD="$password" ENV_SYNC_AUTH="$auth" ENV_SYNC_DIRECT="$direct" \
    ENV_SYNC_REPLICA="$replica" mongosh --nodb --quiet --eval '
      const e = process.env;
      const credentials = e.ENV_SYNC_USER ? encodeURIComponent(e.ENV_SYNC_USER) + ":" + encodeURIComponent(e.ENV_SYNC_PASSWORD) + "@" : "";
      print("mongodb://" + credentials + e.ENV_SYNC_HOST + ":" + e.ENV_SYNC_PORT +
        "/?authSource=" + encodeURIComponent(e.ENV_SYNC_AUTH) + "&directConnection=" + e.ENV_SYNC_DIRECT +
        "&serverSelectionTimeoutMS=10000" + (e.ENV_SYNC_REPLICA ? "&replicaSet=" + encodeURIComponent(e.ENV_SYNC_REPLICA) : ""));
    '
}

# Args: connection prefix. Set its *_URI from DB_* settings unless already supplied.
# Open an enabled SSH tunnel and use its local port with a direct connection.
build_uri() {
  local prefix=$1 uri host port direct
  uri=$(read_setting "$prefix" URI)
  [ -z "$uri" ] || return 0
  host=$(read_setting "$prefix" DB_HOST)
  port=$(read_setting "$prefix" DB_PORT)
  direct=$(read_setting "$prefix" DB_DIRECT_CONNECTION)
  [ -n "$host" ] && [ -n "$port" ] || { echo "ERROR: $prefix host/port missing" >&2; exit 1; }
  if [ "$(read_setting "$prefix" TUNNEL_ENABLED)" = true ]; then
    open_configured_tunnel "$prefix" "$host" "$port"
    host=localhost
    port=$(read_setting "$prefix" TUNNEL_LOCAL_PORT)
    direct=true
  fi
  uri=$(generate_uri "$host" "$port" \
    "$(read_setting "$prefix" DB_USERNAME)" \
    "$(read_setting "$prefix" DB_PASSWORD)" \
    "$(read_setting "$prefix" DB_AUTH_DATABASE)" "$direct" \
    "$(read_setting "$prefix" DB_REPLICA_SET)")
  printf -v "${prefix}_URI" '%s' "$uri"
}

ENV_FILE=""
CLI_SYNC_MODE=""
SHOW_HELP=false
HELPER=""

# Args: command-line arguments. Set ENV_FILE, CLI_SYNC_MODE and SHOW_HELP.
# Return nonzero for unknown options or a missing --env argument.
parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --env)
        [ $# -ge 2 ] || { echo "ERROR: --env requires a path" >&2; return 1; }
        ENV_FILE=$2
        shift 2
        ;;
      --env=*) ENV_FILE=${1#--env=}; shift ;;
      --incremental) CLI_SYNC_MODE=incremental; shift ;;
      --replace) CLI_SYNC_MODE=replace; shift ;;
      -h|--help) SHOW_HELP=true; return ;;
      *) echo "ERROR: unknown argument: $1" >&2; return 1 ;;
    esac
  done
}

# Load ENV_FILE, normalize collection/database lists and validate SYNC_MODE.
# Apply CLI_SYNC_MODE last so the command-line mode takes precedence.
load_configuration() {
  [ -z "$ENV_FILE" ] || load_env_file "$ENV_FILE"
  normalize_array_var COLLECTIONS
  normalize_array_var SYSTEM_DATABASES
  [ -z "$CLI_SYNC_MODE" ] || SYNC_MODE=$CLI_SYNC_MODE
  case "$SYNC_MODE" in
    replace|incremental) ;;
    *) echo "ERROR: invalid SYNC_MODE '$SYNC_MODE'" >&2; return 1 ;;
  esac
}

# Check that tools needed by the selected mode are available on PATH.
# Return nonzero with the missing tool name before opening any connections.
require_tools() {
  local tools=(mongosh flock)
  [ "$SYNC_MODE" != replace ] || tools+=(mongodump mongorestore)
  local tool
  for tool in "${tools[@]}"; do
    command -v "$tool" >/dev/null || { echo "ERROR: missing tool: $tool" >&2; return 1; }
  done
}

# Acquire the process-held lock on descriptor 9, create a private WORK_DIR
# and resolve HELPER beside this script. Fail if another run holds the lock.
prepare_workspace() {
  # Hold the lock for the entire process, including SSH tunnels.
  exec 9>"$SYNC_LOCK_FILE"
  flock -n 9 || { echo "ERROR: another env-sync run holds $SYNC_LOCK_FILE" >&2; return 1; }
  umask 077
  WORK_DIR=$(mktemp -d)
  HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env-sync.js"
  [ -f "$HELPER" ] || { echo "ERROR: missing helper: $HELPER" >&2; return 1; }
}

# Export connection and sync settings for the mongosh helper, serializing
# Bash collection/database arrays as newline-separated environment values.
export_configuration() {
  export SOURCE_URI DESTINATION_URI EXCLUDED_COLLECTIONS
  export SYNC_BATCH_SIZE SYNC_MAX_ATTEMPTS SYNC_RETRY_DELAY_MS
  ENV_SYNC_COLLECTIONS=$(printf '%s\n' "${COLLECTIONS[@]-}")
  ENV_SYNC_SYSTEM_DATABASES=$(printf '%s\n' "${SYSTEM_DATABASES[@]-}")
  export ENV_SYNC_COLLECTIONS ENV_SYNC_SYSTEM_DATABASES
}

# Args: plan or upsert action. Execute HELPER and propagate its exit status.
# Plan output goes to stdout; helper status messages go to stderr.
run_helper() {
  ENV_SYNC_ACTION=$1 mongosh --nodb --quiet --file "$HELPER"
}

# Write source/destination URI configs inside private WORK_DIR so MongoDB
# Database Tools can authenticate without credentials in their process arguments.
write_restore_configs() {
  # Private tool configs keep credentials out of process arguments.
  ENV_SYNC_CONFIG_DIR="$WORK_DIR" mongosh --nodb --quiet --eval '
    const fs = require("fs"), e = process.env;
    fs.writeFileSync(e.ENV_SYNC_CONFIG_DIR + "/source.yml", "uri: " + JSON.stringify(e.SOURCE_URI) + "\n");
    fs.writeFileSync(e.ENV_SYNC_CONFIG_DIR + "/destination.yml", "uri: " + JSON.stringify(e.DESTINATION_URI) + "\n");
  '
}

# Args: source database/collection, destination database/collection, size in bytes.
# Drop and restore one target, including metadata; pipefail propagates either tool’s failure.
restore_collection() {
  local src_db=$1 src_coll=$2 dest_db=$3 dest_coll=$4 size=$5
  echo "  $src_db.$src_coll → $dest_db.$dest_coll ($size bytes, replace)"
  mongodump --config="$WORK_DIR/source.yml" --db="$src_db" --collection="$src_coll" --archive --gzip |
    mongorestore --config="$WORK_DIR/destination.yml" --archive --gzip --drop --stopOnError \
      --nsInclude="$src_db.$src_coll" --nsFrom="$src_db.$src_coll" --nsTo="$dest_db.$dest_coll" \
      --numInsertionWorkersPerCollection=1
}

# Generate the complete sorted plan before destructive work, prepare credential
# configs and restore each included collection sequentially.
run_replace() {
  # Complete discovery/validation before the first destructive restore.
  run_helper plan > "$WORK_DIR/plan"
  write_restore_configs
  local src_db src_coll dest_db dest_coll size
  while IFS=$'\t' read -r src_db src_coll dest_db dest_coll size; do
    [ -n "$src_db" ] || continue
    restore_collection "$src_db" "$src_coll" "$dest_db" "$dest_coll" "$size"
  done < "$WORK_DIR/plan"
}

# Dispatch the selected sync mode and print completion only after it succeeds.
run_migration() {
  echo "Starting migration ($SYNC_MODE, smallest collections first) ..."
  case "$SYNC_MODE" in
    incremental) run_helper upsert ;;
    replace) run_replace ;;
  esac
  echo "Migration complete."
}

# Args: command-line arguments. Coordinate configuration, tool checks, locking,
# connections and sync; the EXIT trap cleans up temporary files and tunnels.
main() {
  parse_arguments "$@"
  if [ "$SHOW_HELP" = true ]; then usage; return; fi
  load_configuration
  require_tools
  prepare_workspace
  build_uri SOURCE
  build_uri DESTINATION
  export_configuration
  run_migration
}

main "$@"
