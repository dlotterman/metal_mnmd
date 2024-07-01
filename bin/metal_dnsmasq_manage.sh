logger "running /opt/equinix/metal/bin/metal_dnsmasq_mangle.sh"
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh
mkdir -p /etc/dnsmasq.d/
cat > /etc/dnsmasq.conf << EOL
expand-hosts
domain-needed
bogus-priv
dns-forward-max=150
cache-size=19968
neg-ttl=60
no-poll
server=147.75.207.207
server=147.75.207.208
domain=$MINIO_DOMAIN,$MINIO_SUBNET.0/24,local
synth-domain=$MINIO_DOMAIN,$MINIO_SUBNET.0/24,$HOST_TYPE-*
local=/$MINIO_DOMAIN/
interface=$BOND.$MINIO_VLAN
bind-interfaces
listen-address=127.0.0.1
listen-address=127.0.0.53
conf-dir=/etc/dnsmasq.d/
EOL
rm /etc/dnsmasq.d/minio.conf > /dev/null 2>&1
for i in $(seq 2 $NUM_INSTANCES); do
# .private is always inside the cluster, mostly for ssl cert reasons
# the object/host-VLAN.privates are outside names
		echo "host-record=object.$MINIO_DOMAIN,$MINIO_SUBNET.$i" >> /etc/dnsmasq.d/minio.conf
        echo "host-record=object-$MINIO_VLAN.$MINIO_DOMAIN,$MINIO_SUBNET.$i" >> /etc/dnsmasq.d/minio.conf
        echo "host-record=object.$MINIO_VLAN.$MINIO_DOMAIN,$MINIO_SUBNET.$i" >> /etc/dnsmasq.d/minio.conf
        echo "host-record=$HOST_TYPE-$i-$MINIO_VLAN.$MINIO_DOMAIN,$MINIO_SUBNET.$i" >> /etc/dnsmasq.d/minio.conf
        echo "host-record=$HOST_TYPE-$i.$MINIO_VLAN.$MINIO_DOMAIN,$MINIO_SUBNET.$i" >> /etc/dnsmasq.d/minio.conf

done
for LINE in $ADNS; do
    SERVERS=$(echo $LINE | awk -F ':' '{print$1}')
    DOMAIN=$(echo $LINE | awk -F ':' '{print$NF}')
    for SERVER in $(echo $SERVERS | awk -F'-' '{ for(i=1;i<=NF;i++) print $i }') ; do
        echo "server=/"$DOMAIN"/"$SERVER"" >> /etc/dnsmasq.d/minio.conf
    done
done
logger "disabling systemd-resolved, may look like an error"
systemctl disable --now systemd-resolved.service
sleep 1
systemctl enable --now dnsmasq.service
systemctl restart dnsmasq.service
