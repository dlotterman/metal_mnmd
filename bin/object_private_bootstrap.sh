logger "starting /opt/equinix/metal/bin/object_private_bootstrap.sh"
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh
if test ! -f /opt/equinix/metal/tmp/object_private_bootstrap.lock; then

	mc --insecure alias set object_private https://127.0.0.1:9000 minioadmin $MINIO_PASSWORD
	if [[ "$MINIO_DOMAIN" != "private" ]]; then
		mc alias set $(echo $MINIO_DOMAIN | tr -d '.' | tr -d '-') https://"$MINIO_DOMAIN":9000 minioadmin "$MINIO_PASSWORD"
	fi
    cp -f /opt/equinix/metal/bin/minio_schema_backup.sh /etc/cron.hourly/
    chmod +x /opt/equinix/metal/bin/minio_schema_backup.sh
    if [[ "$MINIO_INSTANCE" == 2 ]]; then
        logger "since I'm node 2, doing bootstrap toil"
        mc --insecure admin prometheus generate object_private | grep -v scrape_conf >> /opt/equinix/metal/tmp/minio_scrape_config.yaml
        mc --insecure admin user add object_private BENCHMARKUSER BENCHMARKKEY
        mc --insecure admin policy attach object_private readwrite --user BENCHMARKUSER
        mc --insecure mb object_private/bucket1
        mc --insecure mb object_private/bucket2
        mc --insecure mb object_private/bucket1-target
        mc --insecure mb object_private/bucket2-target
        bash /opt/equinix/metal/bin/metal_monitoring_mangle.sh
    fi
    touch /opt/equinix/metal/tmp/object_private_bootstrap.lock
else
    cp -f /opt/equinix/metal/bin/minio_schema_backup.sh /etc/cron.hourly/
    chmod +x /opt/equinix/metal/bin/minio_schema_backup.sh
fi
