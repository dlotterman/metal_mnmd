logger "running /opt/equinix/metal/bin/minio_binary_mangle.sh"
if test ! -f /opt/equinix/metal/tmp/minio_binary_mangle.lock; then
	wget --quiet http://ipxe.dlott.casa/util/minio
	wget --quiet http://ipxe.dlott.casa/util/mc
	wget --quiet http://ipxe.dlott.casa/util/warp
	wget --quiet http://ipxe.dlott.casa/util/sidekick
	chmod +x minio
	chmod +x mc
	chmod +x warp
	chmod +x sidekick
	mv minio /usr/local/bin/
	mv mc /usr/local/bin/
	mv warp /usr/local/bin/
	mv sidekick /usr/local/bin/
	touch /opt/equinix/metal/tmp/minio_binary_mangle.lock
else
	wget --quiet https://dl.min.io/server/minio/release/linux-amd64/minio
	wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc
	chmod +x minio
	chmod +x mc
	mv minio /usr/local/bin/
	mv mc /usr/local/bin/
fi
