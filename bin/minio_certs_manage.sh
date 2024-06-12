logger "running /opt/equinix/metal/bin/minio_certs_manage.sh"
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh
if test -f /opt/equinix/metal/tmp/minio_certs_manage.lock; then
		logger "certgen lock exists, exiting"
		exit 0
else
		true
fi
if test ! -f /root/certgen; then
		wget -O certgen --quiet https://github.com/minio/certgen/releases/latest/download/certgen-linux-amd64
        chmod +x certgen
else
		true
fi
mkdir -p /home/minio-user/.minio/certs
cat > /home/minio-user/.minio/certs/private.key << EOL
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgLgSzXQp9uiCcuYi1
pDkPNwSFFpENu2TyDmbwXkmGQu6hRANCAAS2uclYtEYZ1FaFkih0z2VYJJmH/hVe
YH1NdzeAPf/XJM1+q6wdd1p7pO1L7fsXsg6opG0T8bBh6FIk5CVYeV53
-----END PRIVATE KEY-----
EOL
cat > /home/minio-user/.minio/certs/public.crt << EOL
-----BEGIN CERTIFICATE-----
MIICDDCCAbKgAwIBAgIQTpNNQyfJf7G6jtcR/F8EOjAKBggqhkjOPQQDAjA3MRww
GgYDVQQKExNDZXJ0Z2VuIERldmVsb3BtZW50MRcwFQYDVQQLDA5taW5pby11c2Vy
QG0tMjAeFw0yNDA2MDkwMDE4NTlaFw0yNTA2MDkwMDE4NTlaMDcxHDAaBgNVBAoT
E0NlcnRnZW4gRGV2ZWxvcG1lbnQxFzAVBgNVBAsMDm1pbmlvLXVzZXJAbS0yMFkw
EwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtrnJWLRGGdRWhZIodM9lWCSZh/4VXmB9
TXc3gD3/1yTNfqusHXdae6TtS+37F7IOqKRtE/GwYehSJOQlWHled6OBnzCBnDAO
BgNVHQ8BAf8EBAMCAqQwEwYDVR0lBAwwCgYIKwYBBQUHAwEwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUR5eeush1hD4N5f0V3lH4gTEv7c8wRQYDVR0RBD4wPIIJ
bG9jYWxob3N0gg5vYmplY3QucHJpdmF0ZYIHcHJpdmF0ZYIJKi5wcml2YXRlggsq
LjAucHJpdmF0ZTAKBggqhkjOPQQDAgNIADBFAiBfX1vOG8uxz2amgyKz5qQQHdQX
Pw6dFvow6KUnW95JhAIhAPElt5kWjfSsBZp6uF009QUwR6386VQ+OMCupnB7Oo1f
-----END CERTIFICATE-----
EOL
chown -R minio-user /home/minio-user/.minio/certs
touch /opt/equinix/metal/tmp/minio_certs_manage.lock
