#!/bin/bash
logger "starting metal_ubuntu_automated_updates.sh"
if test -f /opt/equinix/.tmp/metal_ubuntu_automated_updates.lock; then
	logger "automatic updates already enabled, exiting"
	exit 0
else
	logger "enabling automatic updates"
	cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOL
Unattended-Upgrade::Allowed-Origins {
"${distro_id}:${distro_codename}";
"${distro_id}:${distro_codename}-updates";
"${distro_id}:${distro_codename}-security";
"${distro_id}ESMApps:${distro_codename}-apps-security";
"${distro_id}ESM:${distro_codename}-infra-security";
};
EOL
chmod 0744 /etc/apt/apt.conf.d/50unattended-upgrades
cat > /etc/apt/apt.conf.d/21auto-upgrades_on << EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL
chmod 0744 /etc/apt/apt.conf.d/21auto-upgrades_on
cat > /etc/crontab << EOL
05 * * * * root /usr/bin/unattended-upgrade -v
05 11 * * * root systemctl restart sshd
15 11 * * * root systemctl restart serial-getty@ttyS1.service
20 11 * * * root systemctl restart getty@tty1.service
EOL
chmod 0744 /etc/crontab
systemctl enable --now unattended-upgrades
bash /usr/lib/apt/apt.systemd.daily
logger "ending metal_ubuntu_automated_updates.sh"
fi
