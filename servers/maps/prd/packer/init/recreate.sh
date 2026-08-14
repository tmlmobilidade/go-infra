#!/bin/bash

# Define variables
SCRIPT_PATH="/usr/local/bin/maps-updater.sh"
SERVICE_PATH="/etc/systemd/system/maps-updater.service"
USERNAME="root"
GROUP="root"

# Create the script file
echo "Creating the script file..."
cat <<'EOF' | sudo tee $SCRIPT_PATH > /dev/null
#!/bin/sh

while true; do
	echo "Changing directory to '/opt/app'..."
	cd /opt/app/persistent-data/
	# Check if "next.mbtiles" exists
	if [ -f "./tileserver/next.mbtiles" ]; then
		# Check if "current.mbtiles" exists
		if [ -f "./tileserver/current.mbtiles" ]; then
			# Remove "previous.mbtiles" if it exists
			if [ -f "./tileserver/previous.mbtiles" ]; then
				echo "Removing 'previous.mbtiles'..."
				rm ./tileserver/previous.mbtiles
			fi
			echo "Renaming 'current.mbtiles' to 'previous.mbtiles'..."
			mv ./tileserver/current.mbtiles ./tileserver/previous.mbtiles
		fi
		echo "Renaming 'next.mbtiles' to 'current.mbtiles'..."
		mv ./tileserver/next.mbtiles ./tileserver/current.mbtiles
	fi
	echo "Updated files."
	echo "Recreating planetiler...";
	docker compose -f /opt/app/compose.yaml up -d --build --force-recreate --remove-orphans --pull=always planetiler
	echo "Done! Planetiler recreated.";
	sleep 86400; # Sleep for 24 hours
done;
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
