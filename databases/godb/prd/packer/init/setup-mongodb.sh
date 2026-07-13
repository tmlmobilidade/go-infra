#!/usr/bin/env bash

set -euo pipefail

# # #
# SETTINGS

# This is the persistent-data directory where MongoDB
# files and data will be stored. It is expected to be mounted
# as a block volume at /opt/app/persistent-data by attach-volume.sh.
BASE_DIR="/opt/app/persistent-data"


# 1.
# Create the directory structure for
# MongoDB data and logs and set appropriate
# ownership and permissions.

mkdir -p "$BASE_DIR/data"
mkdir -p "$BASE_DIR/logs"

chown -R 999:999 "$BASE_DIR/data"
chown -R 999:999 "$BASE_DIR/logs"

chmod -R 770 "$BASE_DIR/data"
chmod -R 770 "$BASE_DIR/logs"