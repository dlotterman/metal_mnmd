#!/bin/bash
if test ! -f /opt/equinix/metal/tmp/metal_network_setup.lock; then
		logger "running /opt/equinix/metal/bin/metal_network_setup.sh"
		cp /etc/network/interfaces /opt/equinix/metal/tmp/interfaces.orig
else
		logger "refreshing network"
		cp -f /opt/equinix/metal/tmp/interfaces.orig /etc/network/interfaces
fi
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh
echo "" >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "auto $BOND.$MINIO_VLAN" >> /etc/network/interfaces
echo "iface $BOND.$MINIO_VLAN inet static" >> /etc/network/interfaces
echo "      address $MINIO_SUBNET.$MINIO_INSTANCE" >> /etc/network/interfaces
echo "      netmask 255.255.255.0" >> /etc/network/interfaces
for ROUTE in $MINIO_ROUTES; do
    echo "      post-up route add -net $ROUTE/24 gw $MINIO_GW" >> /etc/network/interfaces
    echo "      post-down route del -net $ROUTE/24 gw $MINIO_GW" >> /etc/network/interfaces
    ufw allow from $ROUTE/24 to any port 9000
    ufw allow from $ROUTE/24 to any port 53
    ufw allow from $ROUTE/24 to any port 53
    ip route add $ROUTE/24 via $MINIO_GW
done

ifup $BOND.$MINIO_VLAN

ufw allow from $MINIO_SUBNET.0/24 to any port 9000
ufw allow from $MINIO_SUBNET.0/24 to any port 9001
ufw allow from $MINIO_SUBNET.0/24 to any port 9981
ufw allow from $MINIO_SUBNET.0/24 to any port 53
ufw allow from $MINIO_SUBNET.0/24 to any port 9100
ufw allow from $MINIO_SUBNET.0/24 to any port 7761

ip link set dev $BOND mtu 9000
ip link set dev $BOND.$MINIO_VLAN mtu 9000

for ANETWORK in $ANETWORKS; do
    logger "adding $ANETWORK"
	echo "" >> /etc/network/interfaces
	echo "" >> /etc/network/interfaces
	ANETWORKVLAN=$(echo $ANETWORK | awk -F '-' '{print$1}')
	ANETWORKSUBNET=$(echo $ANETWORK | awk -F '-' '{print$NF')
	echo "auto $BOND.$ANETWORKVLAN" >> /etc/network/interfaces
	echo "iface $BOND.$MINIO_VLAN inet static" >> /etc/network/interfaces
	echo "      address $ANETWORKSUBNET.$MINIO_INSTANCE" >> /etc/network/interfaces
	echo "      netmask 255.255.255.0" >> /etc/network/interfaces
	for AROUTE in $AROUTES; do
		AROUTEVLAN=$(echo $AROUTE | awk -F '-' '{print$1}')
		AROUTESUBNET=$(echo $AROUTE | awk -F '-' '{print$NF')
		if [[ "$ANETWORKVLAN" == "$AROUTEVLAN" ]]; then
		    logger "adding $AROUTE"
			echo "      post-up route add -net $AROUTESUBNET.0 gw $AROUTESUBNET.1" >> /etc/network/interfaces
			echo "      post-down route del -net $AROUTESUBNET.0 gw $AROUTESUBNET.1" >> /etc/network/interfaces
		fi
		ufw allow from $MINIO_SUBNET.0/24 to any port 9000
		ufw allow from $MINIO_SUBNET.0/24 to any port 53/tcp
		ufw allow from $MINIO_SUBNET.0/24 to any port 53/udp
	done
	ifup $BOND.$ANETWORKVLAN
    ip link set dev $BOND.$ANETWORKVLAN mtu 9000
done

if [ -n "$MMNMD_FIREWALL_HOLE" ]; then
    logger "punching hole in firewall for $MMNMD_FIREWALL_HOLE"
    ufw allow from $MMNMD_FIREWALL_HOLE to any
fi

touch /opt/equinix/metal/tmp/metal_network_setup.lock
