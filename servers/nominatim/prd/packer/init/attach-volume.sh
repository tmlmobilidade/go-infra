#!/usr/bin/env bash

set -euo pipefail

# # #
# SETTINGS

# This is the path for the pre-attached OCI block volume.
# It is alphabetically named (e.g. ...oraclevdb, ...oraclevdc, etc.)
# according to the order of attachment, so `b` is the first attached volume.
BLOCK_VOLUME_PATH="/dev/sdb"

# This is the directory where the volume
# will be mounted and accessible in the filesystem.
MOUNT_POINT="/opt/app/persistent-data"


# 1.
# Check if the volume is already mounted
# (e.g. from a previous run or if the script is re-run)
# and exit early if so, to avoid redundant operations and potential issues.

if findmnt -rno TARGET "$MOUNT_POINT" >/dev/null 2>&1; then
	echo "[attach-volume] Already mounted at $MOUNT_POINT"
	exit 0
fi


# 2.
# Wait for OCI block volume to appear by checking the expected device path
# after waiting for 10 seconds for the system to recognize it.

sleep 10

if [[ -b "$BLOCK_VOLUME_PATH" ]]; then
	echo "[attach-volume] Found device: $BLOCK_VOLUME_PATH"
else
	echo "[attach-volume] ERROR: OCI block volume not found at $BLOCK_VOLUME_PATH" >&2
	exit 1
fi


# 3.
# Ensure mount point exists. This is necessary before mounting
# the volume, and also ensures that the directory is present
# for any subsequent operations that rely on it.

mkdir -p "$MOUNT_POINT"


# 4.
# Check if the block volume already has a filesystem.
# This happens when the volume is being attached to a new instance
# but has been previously used. This is the most likely scenario.
# If the volume already has a filesystem, skip this formatting step
# to avoid data loss.

if blkid "$BLOCK_VOLUME_PATH" >/dev/null 2>&1; then
	echo "[attach-volume] Filesystem exists on $BLOCK_VOLUME_PATH. Skipping format to avoid data loss."
else
	echo "[attach-volume] No filesystem found. Formating disk by creating filesystem on $BLOCK_VOLUME_PATH"
	mkfs.xfs "$BLOCK_VOLUME_PATH"
fi


# 5.
# Mount the block volume to the specified mount point.
# This makes the volume accessible in the filesystem.

if ! mount | grep -q "$MOUNT_POINT"; then
	echo "[attach-volume] Mounting $BLOCK_VOLUME_PATH on $MOUNT_POINT"
	mount "$BLOCK_VOLUME_PATH" "$MOUNT_POINT"
fi


# 6.
# Persist using stable UUID, instead of only device path,
# which can sometimes change across reboots.
# Adding to `/etc/fstab` ensures that the volume will be
# automatically mounted on machine reboot.

UUID=$(blkid -s UUID -o value "$BLOCK_VOLUME_PATH")

if ! grep -q "$MOUNT_POINT" /etc/fstab; then
	echo "UUID=$UUID $MOUNT_POINT xfs defaults,noatime,_netdev 0 0" >> /etc/fstab
	echo "[attach-volume] Added to fstab with UUID=$UUID"
fi

echo "[attach-volume] Operation completed successfully. Volume mounted at $MOUNT_POINT"