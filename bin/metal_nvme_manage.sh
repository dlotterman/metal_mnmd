logger "runing /opt/equinix/metal/bin/metal_nvme_manage.sh"

if test ! -f  /opt/equinix/metal/tmp/metal_nvme_manage.lock; then
		logger "setting up nvme"
else
		logger "exiting /opt/equinix/metal/bin/metal_nvme_manage.sh, lock exists, presumed OK"
		exit 0
fi

# We grep out TB here for the systems that have 256GB boot NVMes
NVME_DRIVES=$(nvme list-subsys | grep pci | awk '{print"/dev/"$2}')
for DRIVE in $NVME_DRIVES; do
	logger "working on nvme $DRIVE"
	CONTRLID=$(nvme id-ctrl $DRIVE | grep cntlid | awk '{print$NF}')
	TOTAL_NAMESPACES=$(nvme id-ctrl $DRIVE | grep nn | awk '{print$NF}')
	if [[ "$TOTAL_NAMESPACES" == 0 ]]; then
		logger "cannot operate on drives with no namespace support, drive $DRIVE"
		continue
	elif [[ "$TOTAL_NAMESPACES" == 1 ]]; then
		logger "cannot operate on drives with no namespace support, drive $DRIVE"
		continue
	fi
	if test -z "$TOTAL_NAMESPACES"; then
		logger "cannot operate on drives with no namespace support, drive $DRIVE"
		continue
	fi
	TOTAL_SPACE=$(nvme id-ctrl $DRIVE | grep tnvmcap | awk '{print$NF}')
	if [[ "$TOTAL_SPACE" -lt 3800000000000 ]]; then
		logger "drive $DRIVE to small to be a Metal data drive"
		continue
	fi
	# Sigh, you can get varying features of NS
	#HALF_NAMESPACES=$(( $TOTAL_NAMESPACES / 2 ))
	# Magic numbering this
	HALF_NAMESPACES=16
	for NS in $(seq 1 $TOTAL_NAMESPACES); do
		nvme detach-ns $DRIVE -n $NS -c $CONTRLID > /dev/null 2>&1
		sleep .1
		nvme ns-rescan $DRIVE > /dev/null 2>&1
		nvme delete-ns $DRIVE -n $NS > /dev/null 2>&1
	done
	nvme ns-rescan $DRIVE
	TOTAL_BS_SPACE=$(echo "$TOTAL_SPACE/4096" | bc)
	SPACE_PER_DRIVE=$(( $TOTAL_BS_SPACE / $HALF_NAMESPACES ))
	#SPACE_PER_DRIVE_HEADROOM=$(echo "$SPACE_PER_DRIVE*.8" | bc)
	SPACE_PER_DRIVE_HEADROOM=$(echo $SPACE_PER_DRIVE | awk '{print int($1*.96)}')
	for NS in $(seq 1 $HALF_NAMESPACES); do
		nvme create-ns $DRIVE -s $SPACE_PER_DRIVE_HEADROOM -c $SPACE_PER_DRIVE_HEADROOM -b 4096
		sleep .1
		nvme ns-rescan $DRIVE
		nvme attach-ns $DRIVE -n $NS -c $CONTRLID
		sleep .1
		nvme ns-rescan $DRIVE
	done
done
partprobe
sleep 1
sync
udevadm settle
touch /opt/equinix/metal/tmp/metal_nvme_manage.lock
