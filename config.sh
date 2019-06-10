#!/bin/bash

function log() {
	ts=$(date +"%Y-%m-%d %H:%M:%S")
	echo "$ts $@" >> /boot/install.log	
}

cp -Rf etc/* /etc
cp -Rf usr/* /usr
mkdir /mnt/usb 2>/dev/null

log "Enabling usb storge service."
systemctl enable usb-storage

check_cron=$(crontab -l | grep usb_refresh)
if [ -z "$check_cron" ]; then
	log "Adding crontabs to root."
	(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/usb_refresh") | crontab -
	(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/usb_purge.sh") | crontab -
	(crontab -l 2>/dev/null; echo "@reboot /usr/local/bin/usb_update_config.sh") | crontab -
fi

check_smb=$(grep TeslaCam /etc/samba/smb.conf)
if [ -z "$check_smb" ]; then
	log "Configuring smb."
	echo "[TeslaCam]" >> /etc/samba/smb.conf
	echo "  comment = Tesla DashCam videos" >> /etc/samba/smb.conf
	echo "  path = /mnt/usb" >> /etc/samba/smb.conf
	echo "  browseable = yes" >> /etc/samba/smb.conf
	echo "  read only = no" >> /etc/samba/smb.conf
	echo "  guest ok = yes" >> /etc/samba/smb.conf
fi

echo "dtoverlay=dwc2" >> /boot/config.txt
echo "over_voltage=6" >> /boot/config.txt

a2enmod ssl
a2enmod cgid
a2dissite 000-default
a2ensite default-ssl

echo "www-data ALL = NOPASSWD: /usr/local/bin/" >> /etc/sudoers
echo "www-data ALL = NOPASSWD: /bin/mv" >> /etc/sudoers
echo "www-data ALL = NOPASSWD: /usr/bin/tee" >> /etc/sudoers
