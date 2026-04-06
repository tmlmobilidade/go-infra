#!/usr/bin/env bash

set -euo pipefail

# 1.
# Open Clickhouse's default ports `8123`, `9000`, `9444`, `2181` in the firewall
# to allow external connections from within the private subnet. This is necessary
# for the cluster to function properly, as the nodes need to communicate with each
# other and with clients. The firewall appears to block incoming connections
# by default, so we need to explicitly allow it.

echo "[firewall] Clearing restrictive iptables rules..."
sudo iptables -I INPUT 1 -p tcp --dport 8123 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 9000 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 9009 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 9444 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 2181 -j ACCEPT
echo "[firewall] iptables rules cleared."