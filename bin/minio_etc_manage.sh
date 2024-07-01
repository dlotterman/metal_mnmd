logger "running /opt/equinix/metal/bin/minio_etc_default_manage.sh"
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh
cat > /etc/default/minio << EOL
MINIO_VOLUMES="$SORTED_STR_VOL"
MINIO_OPTS="--console-address :9001"
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=Equinixmetal05
MINIO_PROMETHEUS_AUTH_TYPE="public"
MINIO_SERVER_URL="https://object.private:9000"
MINIO_SCANNER_SPEED="fastest"
EOL
chmod 0750 /etc/default/minio
chown "minio-user:cloud-users" /etc/default/minio
cp /opt/equinix/metal/tmp/metal_mnmd/etc/systemd/minio.service /etc/systemd/system/minio.service
cp /opt/equinix/metal/tmp/metal_mnmd/etc/systemd/warp.service /etc/systemd/system/warp.service
systemctl daemon-reload
systemctl stop warp.service
systemctl enable --now warp.service
sleep 1
logger "minio_etc_default_manage: done"
