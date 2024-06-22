#!/bin/bash
if test ! -f  /opt/equinix/metal/tmp/metal_disk_setup.lock; then
		logger "running /opt/equinix/metal/bin/metal_disk_setup.sh"
else
		logger "exiting /opt/equinix/metal/bin/metal_disk_setup.sh, lock exists, presumed OK"
		exit 0
fi
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh
COUNTER=1
for DRIVE in $MINIO_DRIVES ; do
		SHORT_NAME=$(echo $DRIVE | awk -F '/' '{print$NF}')
		sgdisk --zap-all $DRIVE
		mkfs.xfs -f $DRIVE
		mkdir /mnt/disk$COUNTER
		udevadm settle
		sync
		sleep 2
		partprobe
		sleep 2
		udevadm settle
		sync
		DRIVE_UUID=$(ls -al /dev/disk/by-uuid/ | grep $SHORT_NAME | awk '{print$9}')
		if test -z "$DRIVE_UUID"; then
			logger "could not find $SHORT_NAME, trying again"
			sync
			udevadm settle
			partprobe
			sleep 15
			DRIVE_UUID=$(blkid $DRIVE | awk '{print$2}' | awk -F "=" '{print$2}' | tr -d "\"")
		fi
		cat > /etc/systemd/system/mnt-disk$COUNTER.mount << EOL
[Unit]
Description=minio-drive-$DRIVE_UUID
DefaultDependencies=no
Conflicts=umount.target
Before=local-fs.target umount.target
After=swap.target
[Mount]
What=/dev/disk/by-uuid/$DRIVE_UUID
Where=/mnt/disk$COUNTER
Type=xfs
Options=defaults
[Install]
WantedBy=multi-user.target
EOL
if [[ "$NUM_DRIVES" == "$COUNTER" ]]; then
		true
else
		let COUNTER=COUNTER+1
fi
done
sync
sleep 1
systemctl daemon-reload
COUNTER2=1
for DRIVE in $MINIO_DRIVES ; do
		systemctl enable --now mnt-disk$COUNTER2.mount
		chown minio-user:minio-user /mnt/disk$COUNTER2
		let COUNTER2=COUNTER2+1
done
touch /opt/equinix/metal/tmp/metal_disk_setup.lock
