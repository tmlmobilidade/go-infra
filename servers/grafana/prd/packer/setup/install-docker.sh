#!/usr/bin/env bash

set -euo pipefail

echo "[docker] Starting Docker Engine installation..."


wait_for_apt() {
	sleep 15
	while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; do
		echo "APT/dpkg still running..."
		sleep 15
	done
	echo "APT process finished"
}


echo "[docker] Removing old versions..."
wait_for_apt
apt-get remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
echo "[docker] Old versions removed (if any were present)."


echo "[docker] Adding Docker's official GPG key and repository..."
wait_for_apt
apt-get update -qq
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "[docker] Docker GPG key added."


echo "[docker] Adding Docker repository to apt sources..."
wait_for_apt
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
echo "[docker] Docker repository added."


echo "[docker] Installing Docker Engine and related components..."
wait_for_apt
apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "[docker] Docker Engine installation complete."


echo "[docker] Linux post-installation steps for Docker Engine..."
groupadd docker || true
usermod -aG docker ubuntu
newgrp docker
echo "[docker] User 'ubuntu' added to 'docker' group."


echo "[docker] Docker install complete."
docker --version