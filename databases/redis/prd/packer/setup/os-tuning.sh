#!/usr/bin/env bash

set -euo pipefail

# 1.
# Wait for cloud-init to finish before applying any tuning,
# to avoid conflicts with cloud-init's own tuning steps.

echo "[tuning] Waiting for cloud-init to finish (this may take 1-2 minutes)..."
cloud-init status --wait
sleep 30
echo "[tuning] cloud-init finished."