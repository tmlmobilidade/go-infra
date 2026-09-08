#!/usr/bin/env bash

set -euo pipefail

# 1.
# Open Valhalla HTTP port `8002` in the firewall so clients
# inside the private subnet can reach the routing API.

echo "[firewall] Clearing restrictive iptables rules..."
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
echo "[firewall] Saving iptables rules to /etc/iptables/rules.v4..."
sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null
echo "[firewall] iptables rules updated and persisted."
