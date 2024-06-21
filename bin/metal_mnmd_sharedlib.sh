#!/bin/bash
logger "/opt/equinix/metal/bin/metal_mnmd_sharedlib.sh sourced / executed"

mkdir -p mkdir -p /opt/equinix/metal/tmp &> /dev/null
mkdir -p mkdir -p /opt/equinix/metal/etc &> /dev/null

MMNMD_BRANCH=$(grep MMNMD_BRANCH /opt/equinix/metal/etc/metal_tag_extend.env | awk -F "_" '{print$NF}')

CURRENT_TS=$(date +%s)
MMNMD_UPDATE_TS=$(grep MMNMD_UPDATE_ /opt/equinix/metal/etc/metal_tag_extend.env | awk -F '_' '{print$NF}')

DELAYED_START_TS=$(($MMNMD_UPDATE_TS + 5))
DELAYED_START_TS_P2=$(($DELAYED_START_TS + 2))

WAIT_TIME=$(($DELAYED_START_TS_P2 - $CURRENT_TS + 10))

SYSTEM_DRIVE_COUNT=$(lsblk | grep disk | awk '{print$1}' | wc -l)
if [[ "$SYSTEM_DRIVE_COUNT" == 2 ]]; then
    logger "using single disk config"
    mkdir /mnt/disk2
    for S_DRIVE in $(lsblk  | grep disk | awk '{print$1}'); do
    MOUNTS=$(cat /proc/mounts)
        if [[ "$MOUNTS" =~ "$S_DRIVE" ]]; then
                false
            else
                MINIO_DRIVES="/dev/"$S_DRIVE
        fi
    done
    NUM_DRIVES=2
elif test -f  /opt/equinix/metal/tmp/metal_nvme_manage.lock; then
	# I dislike this, but when you split a 3.8TB NVMe by 16, it can
	# be smaller than a potentially present small boot NVMe, making the boot NVMe larger
	# meaning we can't just find the largest disk. So we find the one with the most number of being present
    DRIVE_SIZE=$(lsblk --bytes | awk '{print$4}' | sort | uniq -c  | sort | tail -n1 | awk '{print$2}')
    MINIO_DRIVES=$(lsblk --bytes | grep $DRIVE_SIZE | awk '{print"/dev/"$1}' | tr '\n' ' ')
    NUM_DRIVES=$(echo $MINIO_DRIVES | wc -w)
else
	DRIVE_SIZE=$(lsblk --bytes | grep disk | awk '{print$4}' | sort -nr | head -1)
    MINIO_DRIVES=$(lsblk --bytes | grep $DRIVE_SIZE | awk '{print"/dev/"$1}' | tr '\n' ' ')
    NUM_DRIVES=$(echo $MINIO_DRIVES | wc -w)
fi


if [[ "$NUM_INTERFACES" == 4 ]]; then
BOND="bond1"
else
BOND="bond0"
fi
MINIO_SUBNET=$(grep MMNMD_SUBNET_ /opt/equinix/metal/etc/metal_tag_extend.env | awk -F "_" '{print$NF}')
MINIO_VLAN=$(grep MMNMD_VLAN_ /opt/equinix/metal/etc/metal_tag_extend.env | awk -F "_" '{print$NF}')
MINIO_GW=$(grep MMNMD_VGW_ /opt/equinix/metal/etc/metal_tag_extend.env | awk -F "_" '{print$NF}')
if test -z "$MINIO_GW"; then
  MINIO_GW="$MINIO_SUBNET.1"
else
  MINIO_GW="$MINIO_SUBNET"."$MINIO_GW"
fi
MINIO_INSTANCE=$(hostname | awk -F '-' '{print$NF}')
HOST_TYPE=$(hostname | awk -F '-' '{print$1}')
ANETWORKS=$(grep MMNMD_ANETWORK /opt/equinix/metal/etc/metal_tag_extend.env | awk -F '_' '{print$NF}')
AROUTES=$(grep MMNMD_AROUTE /opt/equinix/metal/etc/metal_tag_extend.env | awk -F '_' '{print$NF}')
MINIO_ROUTES=$(grep MMNMD_ROUTE /opt/equinix/metal/etc/metal_tag_extend.env | awk -F "_" '{print$NF}')
MMNMD_FIREWALL_HOLE=$(grep MMNMD_FIREWALL_HOLE_ /opt/equinix/metal/etc/metal_tag_extend.env | awk -F '_' '{print$NF}')
ADNS=$(grep MMNMD_ADNS /opt/equinix/metal/etc/metal_tag_extend.env | awk -F '_' '{print$NF}')
MINIO_INSTANCE=$(hostname | awk -F '-' '{print$NF}')
NUM_INSTANCES=0
MGROUPS=$(grep MMNMD_GROUP /opt/equinix/metal/etc/metal_tag_extend.env | awk -F '_' '{print$NF}')
MINIO_VOL_STR=""
for MGROUP in $MGROUPS; do
	MGROUP_FIRST=$(echo $MGROUP | awk -F '-' '{print$1}')
	MGROUP_LAST=$(echo $MGROUP | awk -F '-' '{print$NF}')
	MGROUP_VOL_STR="https://$HOST_TYPE-{$MGROUP_FIRST...$MGROUP_LAST}.private:9000/mnt/disk{1...$NUM_DRIVES}/minio"
	NUM_IN_GROUP=$((MGROUP_LAST-MGROUP_FIRST+1))
	MINIO_VOL_STR="${MINIO_VOL_STR} $MGROUP_VOL_STR"
	NUM_INSTANCES=$((NUM_INSTANCES+NUM_IN_GROUP+1))
done
SORTED_STR_VOL=$(echo $MINIO_VOL_STR | xargs -n1 | sort | xargs)
LBT_GROUPS=$(grep MNMD_LBT_GROUP /opt/equinix/metal/etc/metal_tag_extend.env | awk -F '_' '{print$NF}')
