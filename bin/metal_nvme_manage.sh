logger "runing /opt/equinix/metal/bin/metal_nvme_manage.sh"

if test ! -f  /opt/equinix/metal/tmp/metal_nvme_manage.lock; then
		logger "setting up nvme"
else
		logger "exiting /opt/equinix/metal/bin/metal_nvme_manage.sh, lock exists, presumed OK"
		exit 0
fi

NVME_DRIVES=$(nvme list-subsys | grep pcie | awk '{print"/dev/"$2}')
for DRIVE in $NVME_DRIVES; do
	logger "working on nvme $DRIVE"
	CONTRLID=$(nvme id-ctrl $DRIVE | grep cntlid | awk '{print$NF}')
	TOTAL_NAMESPACES=$(nvme id-ctrl /dev/nvme0 | grep nn | awk '{print$NF}')
	if [[ "$TOTAL_NAMESPACES" == 0 ]]; then
		logger "cannot operate on drives with no namespace support"
		exit 0
	fi
	if test -z "$TOTAL_NAMESPACES"; then
		logger "cannot operate on drives with no namespace support"
		exit 0
	fi
	HALF_NAMESPACES=$(( $TOTAL_NAMESPACES / 2 ))
	for NS in $(seq 1 $TOTAL_NAMESPACES); do
		nvme detach-ns $DRIVE -n $NS -c $CONTRLID > /dev/null 2>&1
		sleep .1
		nvme ns-rescan $DRIVE > /dev/null 2>&1
		nvme delete-ns $DRIVE -n $NS > /dev/null 2>&1
	done
	nvme ns-rescan $DRIVE
	TOTAL_SPACE=$(nvme id-ctrl $DRIVE | grep tnvmcap | awk '{print$NF}')
	TOTAL_BS_SPACE=$(echo "$TOTAL_SPACE/4096" | bc)
	SPACE_PER_DRIVE=$(( $TOTAL_BS_SPACE / $HALF_NAMESPACES ))
	#SPACE_PER_DRIVE_HEADROOM=$(echo "$SPACE_PER_DRIVE*.8" | bc)
	SPACE_PER_DRIVE_HEADROOM=$(echo $SPACE_PER_DRIVE | awk '{print $1*.92}')
	for NS in $(seq 1 $HALF_NAMESPACES); do
		nvme create-ns $DRIVE -s $SPACE_PER_DRIVE_HEADROOM -c $SPACE_PER_DRIVE_HEADROOM -b 4096
		sleep .1
		nvme ns-rescan $DRIVE
		nvme attach-ns $DRIVE -n $NS -c $CONTRLID
		sleep .1
		nvme ns-rescan $DRIVE
	done
done
touch /opt/equinix/metal/tmp/metal_nvme_manage.lock
