logger "minio_certs_manage: running /opt/equinix/metal/bin/minio_certs_manage.sh"
# todo: storing certs in three places is dumb
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
mkdir -p /opt/equinix/metal/tmp/export/
mkdir -p /home/minio-user/.minio/certs/
if [[ "$MINIO_INSTANCE" != 2 ]]; then
    logger "minio_certs_manage: waiting for first instance to open certs / nginx"
	until curl --output /dev/null --silent --head --fail http://"$HOST_TYPE"-2."$MINIO_DOMAIN":9981/certs.done; do
		logger "minio_certs_manage: "$HOST_TYPE"-2."$MINIO_DOMAIN":9981 still not up, sleeping"
		sleep 5
	done
	logger "minio_certs_manage: "$HOST_TYPE"-2."$MINIO_DOMAIN":9981 is up, progressing"
	mkdir -p /opt/equinix/metal/tmp/import
	wget -q -O /opt/equinix/metal/tmp/import/private.key http://"$HOST_TYPE"-2."$MINIO_DOMAIN":9981/private.key
	wget -q -O /opt/equinix/metal/tmp/import/public.crt http://"$HOST_TYPE"-2."$MINIO_DOMAIN":9981/public.crt
	cp -f /opt/equinix/metal/tmp/import/private.key /opt/equinix/metal/tmp/export/private.key
	cp -f /opt/equinix/metal/tmp/import/private.key /home/minio-user/.minio/certs/private.key
	cp -f /opt/equinix/metal/tmp/import/private.key /opt/equinix/metal/tmp/private.key
	cp -f /opt/equinix/metal/tmp/import/public.crt /opt/equinix/metal/tmp/export/public.crt
	cp -f /opt/equinix/metal/tmp/import/public.crt /home/minio-user/.minio/certs/public.crt
	cp -f /opt/equinix/metal/tmp/import/public.crt /opt/equinix/metal/tmp/public.crt
	chown -R minio-user /home/minio-user/.minio/certs
	touch /opt/equinix/metal/tmp/minio_certs_manage.lock
    exit 0
fi

if [[ "$MINIO_DOMAIN" == "private" ]]; then
	# We keep fixed certs for easier wireshark / tcpdump
	cp -f /opt/equinix/metal/tmp/metal_mnmd/etc/certs/private.key /home/minio-user/.minio/certs/private.key
	cp -f /opt/equinix/metal/tmp/metal_mnmd/etc/certs/private.key /opt/equinix/metal/tmp/private.key
	cp -f /opt/equinix/metal/tmp/metal_mnmd/etc/certs/private.key /opt/equinix/metal/tmp/export/private.key
	cp -f /opt/equinix/metal/tmp/metal_mnmd/etc/certs/public.crt /home/minio-user/.minio/certs/public.crt
	cp -f /opt/equinix/metal/tmp/metal_mnmd/etc/certs/public.crt /opt/equinix/metal/tmp/public.crt
	cp -f /opt/equinix/metal/tmp/metal_mnmd/etc/certs/public.crt /opt/equinix/metal/tmp/export/public.crt

else
	until [ -f /opt/equinix/metal/tmp/export/certs.done ]; do
		logger "minio_certs_manage: waiting for operator to finish allocating certs"
		sleep 5
	done

	#certbot certonly --manual -d "$MINIO_DOMAIN" -d *."$MINIO_DOMAIN" --staple-ocsp --agree-tos --register-unsafely-without-email --preferred-challenges dns
	#cp -f /etc/letsencrypt/live/$MINIO_DOMAIN/privkey.pem /home/minio-user/.minio/certs/private.key
	#cp -f /etc/letsencrypt/live/$MINIO_DOMAIN/fullchain.pem /home/minio-user/.minio/certs/public.crt
	#echo "mmnmd export dir" > /opt/equinix/metal/tmp/export/landing.html
	#cp -f /etc/letsencrypt/live/$MINIO_DOMAIN/privkey.pem /opt/equinix/metal/tmp/export/private.key
	#cp -f /etc/letsencrypt/live/$MINIO_DOMAIN/privkey.pem /opt/equinix/metal/tmp/private.key

	#cp -f /etc/letsencrypt/live/$MINIO_DOMAIN/fullchain.pem /opt/equinix/metal/tmp/export/public.crt
	#cp -f /etc/letsencrypt/live/$MINIO_DOMAIN/fullchain.pem /opt/equinix/metal/tmp/public.crt
	#touch /opt/equinix/metal/tmp/export/certs.done
fi


chown -R minio-user /home/minio-user/.minio/certs
chown -R www-data /opt/equinix/metal/tmp/export
chmod -R 0755 /opt/equinix/metal/tmp/export
touch /opt/equinix/metal/tmp/minio_certs_manage.lock
logger "minio_certs_manage: done"
