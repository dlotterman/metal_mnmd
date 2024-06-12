#!/bin/bash

source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh

logger "running mmnmd_restart_minio from metal_mnmd_miniolib, this will stop MinIO if needed, then start it"

if test ! -f /opt/equinix/metal/tmp/equinix_mnmd_minio_first_start.lock; then
    logger "first start file not found, assuming frest start, delaying several seconds after intended start time of existing nodes"
	systemd-run --on-calendar "$(date -d @"$DELAYED_START_TS" +'%F %T')" --timer-property=AccuracySec=1us systemctl enable --now minio
	touch /opt/equinix/metal/tmp/equinix_mnmd_minio_first_start.lock

else
    logger "first stack lock file found, assuming we've started before, restart as fast as possible"
	systemd-run --on-calendar "$(date -d @"$MMNMD_UPDATE_TS" +'%F %T')" --timer-property=AccuracySec=1us systemctl restart minio
fi
logger "minio_restart_manage.sh: sleeping till restart"
sleep $WAIT_TIME
logger "minio_restart_manage.sh: done with sleep"
