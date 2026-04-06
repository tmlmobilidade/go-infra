#!/usr/bin/env bash

set -euo pipefail

echo "================================================"
echo "Initializing MongoDB replica set"
echo "================================================"

# ----------------------------
# Parse named arguments
# ----------------------------
NODE_INDEX=""
PORT=""
USERNAME=""
PASSWORD=""
REPLICA_SET_MEMBERS=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--node-index) NODE_INDEX="$2"; shift 2 ;;
		--mongodb-port) PORT="$2"; shift 2 ;;
		--username) USERNAME="$2"; shift 2 ;;
		--password) PASSWORD="$2"; shift 2 ;;
		--replica-set-members) REPLICA_SET_MEMBERS="$2"; shift 2 ;;
		*)
		echo "Unknown argument: $1"
		exit 1
		;;
	esac
done

# Validate required args
: "${NODE_INDEX:?Missing --node-index}"
: "${PORT:?Missing --mongodb-port}"
: "${USERNAME:?Missing --username}"
: "${PASSWORD:?Missing --password}"
: "${REPLICA_SET_MEMBERS:?Missing --replica-set-members}"

# Only primary initializes
if [[ "$NODE_INDEX" -ne 0 ]]; then
  echo "Node $NODE_INDEX: secondary node, skipping rs.initiate()"
  exit 0
fi

# Give mongod a moment to start
sleep 15


wait_for_port() {
  local host="$1"
  local port="$2"

  until nc -z -w 2 "$host" "$port"; do
    echo "Waiting for $host:$port..."
    sleep 2
  done

  echo "$host:$port is reachable"
}


IFS=',' read -ra MEMBERS <<< "$REPLICA_SET_MEMBERS"
for MEMBER in "${MEMBERS[@]}"; do
  wait_for_port "$MEMBER" "$PORT"
done


sleep 15

# echo "Node 0: waiting for mongod to be ready..."
# RETRY=0
# READY=0
# while [ $RETRY -lt 30 ]; do
#   RETRY=$((RETRY + 1))
#   if docker exec mongodb mongosh \
#       --host localhost \
#       --port "$PORT" \
#       --username "$USERNAME" \
#       --password "$PASSWORD" \
#       --authenticationDatabase admin \
#       --quiet \
#       --eval "db.runCommand({ ping: 1 })" 2>/dev/null | grep -q 'ok.*1'; then
#     echo "mongod is ready."
#     READY=1
#     break
#   fi
#   echo "Attempt $RETRY: mongod not ready yet, waiting 10s..."
#   sleep 10
# done

# if [ "$READY" -eq 0 ]; then
#   echo "ERROR: mongod did not become ready after 30 attempts."
#   exit 1
# fi

# ----------------------------
# Run mongosh
# ----------------------------
echo "Node 0: initiating replica set 'rs0'..."

docker compose exec -T mongodb mongosh \
  -u "$USERNAME" \
  -p "$PASSWORD" \
  --authenticationDatabase admin <<EOF
	use admin;
	rs.initiate({
		_id: "rs0",
		members: [
			{ _id: 0, host: "${MEMBERS[0]}:$PORT", priority: 1 },
			{ _id: 1, host: "${MEMBERS[1]}:$PORT", priority: 0.5 },
			{ _id: 2, host: "${MEMBERS[2]}:$PORT", priority: 0.5 }
		]
	})

	// Wait until primary is elected
	while (!rs.isMaster().ismaster) {
		sleep(1000);
	}
EOF

echo "================================================"
echo "Replica set initialization complete"
echo "================================================"