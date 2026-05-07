#!/usr/bin/env bash

set -euo pipefail

# 1.
# Open postgres's default port `5432` in the firewall to allow external connections
# from within the private subnet. This is necessary for the postgres service
# to function properly, as the nodes need to communicate with clients.
# The firewall appears to block incoming connections
# by default, so we need to explicitly allow it.

echo "[firewall] Clearing restrictive iptables rules..."
sudo iptables -I INPUT 1 -p tcp --dport 5432 -j ACCEPT
echo "[firewall] Saving iptables rules to /etc/iptables/rules.v4..."
sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null
echo "[firewall] iptables rules updated and persisted."