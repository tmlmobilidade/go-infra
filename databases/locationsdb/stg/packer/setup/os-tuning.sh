#!/usr/bin/env bash

set -euo pipefail

# 1.
# Wait for cloud-init to finish before applying any tuning,
# to avoid conflicts with cloud-init's own tuning steps.

echo "[tuning] Waiting for cloud-init to finish (this may take 1-2 minutes)..."
cloud-init status --wait
sleep 30
echo "[tuning] cloud-init finished."

# 2.
# Enable memory overcommit to prevent postgres
# from failing under low memory conditions.

echo "[tuning] Enabling memory overcommit..."
if ! grep -q "vm.overcommit_memory" /etc/sysctl.conf; then
	 echo "vm.overcommit_memory = 1" | sudo tee -a /etc/sysctl.conf >/dev/null
	 echo "[tuning] Added 'vm.overcommit_memory = 1' to /etc/sysctl.conf."
else
	 echo "[tuning] 'vm.overcommit_memory' already set in /etc/sysctl.conf, skipping."
fi
sudo sysctl -w vm.overcommit_memory=1
echo "[tuning] Memory overcommit enabled."