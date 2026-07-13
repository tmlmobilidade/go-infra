#!/usr/bin/env bash

set -euo pipefail

# # #
# SETTINGS

# This is the persistent-data directory where ClickHouse
# files and data will be stored. It is expected to be mounted
# as a block volume at /opt/app/persistent-data by attach-volume.sh.
BASE_DIR="/opt/app/persistent-data"


# 1.
# Create the directory structure for
# ClickHouse data and logs and set appropriate
# ownership and permissions.

mkdir -p "$BASE_DIR/data"
mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/config.d"
mkdir -p "$BASE_DIR/users.d"

chown -R 101:101 "$BASE_DIR/data"
chown -R 101:101 "$BASE_DIR/logs"
chown -R ubuntu:ubuntu "$BASE_DIR/config.d"
chown -R ubuntu:ubuntu "$BASE_DIR/users.d"

chmod -R 775 "$BASE_DIR"