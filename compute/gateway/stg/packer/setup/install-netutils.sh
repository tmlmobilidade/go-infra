#!/usr/bin/env bash

set -euo pipefail

echo "[netutils] Starting netutils installation..."


wait_for_apt() {
	sleep 15
	while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; do
		echo "APT/dpkg still running..."
		sleep 15
	done
	echo "APT process finished"
}


# 1.
# Install networking utilities.

echo "[netutils] Installing netutils packages..."
wait_for_apt
apt-get update -qq
apt-get install -y iputils-ping netcat-traditional net-tools
echo "[netutils] netutils packages installation complete."