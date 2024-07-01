logger "minio_certs_manage: running /opt/equinix/metal/bin/minio_certs_manage.sh"
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh

if ! grep -q "MMNMD_GROUP" /opt/equinix/metal/etc/metal_tag_extend.env; then
	logger "dont see group tag applied, exiting / waiting "
	exit 0
fi

if test -f /opt/equinix/metal/tmp/minio_certs_manage.lock; then
		logger "minio_certs_manage: certs lock exists, exiting"
		exit 0
else
		true
fi
if [[ "$MINIO_INSTANCE" != 2 ]]; then
    logger "minio_certs_manage: waiting for first instance to open certs / nginx"
	until curl --output /dev/null --silent --head --fail http://"$HOST_TYPE"-2."$MINIO_DOMAIN":9981; do
		printf logger ""$HOST_TYPE"-2."$MINIO_DOMAIN":9981 still not up, sleeping"
		sleep 5
	done
	mkdir -p /opt/equinix/metal/tmp/import
	wget -O /opt/equinix/metal/tmp/import/private.key http://"$HOST_TYPE"-2."$MINIO_DOMAIN":9981/export/private.key
	wget -O /opt/equinix/metal/tmp/import/public.crt http://"$HOST_TYPE"-2."$MINIO_DOMAIN":9981/export/public.crt
	mkdir -p /home/minio-user/.minio/certs
	cp /opt/equinix/metal/tmp/import/private.key /opt/equinix/metal/tmp/export/private.key
	cp /opt/equinix/metal/tmp/import/public.crt /opt/equinix/metal/tmp/export/public.crt
	chown -R minio-user /home/minio-user/.minio/certs
	touch /opt/equinix/metal/tmp/minio_certs_manage.lock
fi

certbot certonly --standalone -d $MINIO_DOMAIN --staple-ocsp -m ssl@$MINIO_DOMAIN --agree-tos

mkdir -p /home/minio-user/.minio/certs

cp /etc/letsencrypt/live/$MINIO_DOMAIN/privkey.pem /home/minio-user/.minio/certs/private.key
cp /etc/letsencrypt/live/$MINIO_DOMAIN/fullchain.pem /home/minio-user/.minio/certs/public.crt

mkdir -p /opt/equinix/metal/tmp/export
echo "mmnmd export dir" > mkdir -p /opt/equinix/metal/tmp/export/index.html
cp /etc/letsencrypt/live/$MINIO_DOMAIN/privkey.pem mkdir -p /opt/equinix/metal/tmp/export/private.key
cp /etc/letsencrypt/live/$MINIO_DOMAIN/fullchain.pem mkdir -p /opt/equinix/metal/tmp/export/public.crt

chown -R minio-user /home/minio-user/.minio/certs
touch /opt/equinix/metal/tmp/minio_certs_manage.lock
logger "minio_certs_manage: done"
