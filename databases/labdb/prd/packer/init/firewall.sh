#!/usr/bin/env bash

set -euo pipefail

# 1.
# Open Clickhouse's client ports `8123` (HTTP) and `9000` (native TCP) in the
# firewall to allow connections from within the private subnet. The firewall
# appears to block incoming connections by default, so we need to explicitly
# allow it.
#
# The replication ports are deliberately not opened: `9009` (interserver),
# `9444` (Keeper Raft) and `2181` (Keeper client) are only needed once there
# is more than one node.

echo "[firewall] Clearing restrictive iptables rules..."
sudo iptables -I INPUT 1 -p tcp --dport 8123 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 9000 -j ACCEPT
echo "[firewall] Saving iptables rules to /etc/iptables/rules.v4..."
sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null
echo "[firewall] iptables rules updated and persisted."