#!/bin/bash
set -euo pipefail

# Define variables
SCRIPT_PATH="/usr/local/bin/maps-updater.sh"
SERVICE_PATH="/etc/systemd/system/maps-updater.service"
APP_DIR="/opt/app"
USERNAME="${SUDO_USER:-$(whoami)}"
GROUP="$(id -gn "$USERNAME")"

# Create the script file
echo "Creating the script file..."
cat <<'EOF' | sudo tee $SCRIPT_PATH > /dev/null
#!/bin/sh
set -eu

APP_DIR=/opt/app
COMPOSE="docker compose -f $APP_DIR/compose.yaml --project-directory $APP_DIR"

while true; do
	echo "Pull + recreate tileserver ..."
	$COMPOSE pull tileserver
	$COMPOSE up -d --force-recreate --remove-orphans tileserver
	echo "Done! tileserver recreated."
	sleep 86400
done
EOF

# Make the script executable
sudo chmod +x $SCRIPT_PATH
echo "Script created and made executable at $SCRIPT_PATH."

# Create the systemd service file
echo "Creating the systemd service file..."
cat <<EOF | sudo tee $SERVICE_PATH > /dev/null
[Unit]
Description=Maps Updater Daemon
After=docker.service
Requires=docker.service

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=$SCRIPT_PATH
Restart=always
RestartSec=10
User=$USERNAME
Group=$GROUP
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable, and start the service
echo "Setting up the systemd service..."
sudo systemctl daemon-reload
sudo systemctl stop maps-updater.service
sudo systemctl disable maps-updater.service
sudo systemctl daemon-reload
sudo systemctl enable maps-updater.service
sudo systemctl start maps-updater.service

# Verify the service status
echo "Verifying the service status..."
sudo systemctl status maps-updater.service
echo "Setup complete! The Maps Updater Daemon is now running."
