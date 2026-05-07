#!/usr/bin/env bash

set -euo pipefail

# # #
# SETTINGS

# This is the persistent-data directory where Postgres
# files and data will be stored. It is expected to be mounted
# as a block volume at /opt/app/persistent-data by attach-volume.sh.
BASE_DIR="/opt/app/persistent-data"


# 1.
# Create the directory structure for
# Postgres data and set appropriate
# ownership and permissions.
#
# The official `postgres` Docker image runs as
# UID/GID 999 (the `postgres` user inside the
# container), so the host directories must be
# owned by 999:999 for the container to write.

mkdir -p "$BASE_DIR/data"

chown -R 999:999 "$BASE_DIR/data"

chmod -R 700 "$BASE_DIR/data"
