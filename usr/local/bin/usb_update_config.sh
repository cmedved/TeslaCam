#!/bin/bash
BOOT_CONFIG=/boot/teslacam.conf
CONF_FILE=/usr/local/bin/usb_conf.sh

if [ -e /boot/first_boot.sh ]; then
	bash /boot/first_boot.sh >> /boot/install.log 2>&1
	systemctl stop usb-storage
	systemctl start usb-storage
fi

if [ ! -e /var/www/certs ]; then
	domain=teslacam
	country=us
	state=Pennsylvania
	locality=Philadelphia
	organization=TeslaCam
	organizationalunit=TeslaCam

	mkdir -p /var/www/certs
	openssl req -new -x509 -nodes -newkey rsa:2048 -keyout /var/www/certs/$domain.key \
		-out /var/www/certs/$domain.crt -days 1825 -subj \
		"/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$domain"
	service apache2 stop
	service apache2 start 
fi

boot_hostname=$(grep hostname $BOOT_CONFIG | cut -f2- -d '=')
boot_ssid=$(grep wireless_ssid $BOOT_CONFIG | cut -f2- -d '=')
boot_psk=$(grep wireless_psk $BOOT_CONFIG | cut -f2- -d '=')
boot_samba=$(grep samba $BOOT_CONFIG | cut -f2- -d '=')
boot_rsync=$(grep "rsync=" $BOOT_CONFIG | cut -f2- -d '=')
boot_rsync_host=$(grep rsync_host $BOOT_CONFIG | cut -f2- -d '=')
boot_rsync_path=$(grep rsync_path $BOOT_CONFIG | cut -f2- -d '=')
boot_rsync_user=$(grep rsync_user $BOOT_CONFIG | cut -f2- -d '=')
boot_rsync_pass=$(grep rsync_pass $BOOT_CONFIG | cut -f2- -d '=')
boot_rsync_cron=$(grep rsync_cron $BOOT_CONFIG | cut -f2- -d '=')
boot_rsync_delete=$(grep rsync_delete $BOOT_CONFIG | cut -f2- -d '=')
boot_purge=$(grep "auto_purge=" $BOOT_CONFIG | cut -f2- -d '=')
boot_purge_days=$(grep auto_purge_max $BOOT_CONFIG | cut -f2- -d '=')
boot_web_control=$(grep web_control $BOOT_CONFIG | cut -f2- -d '=')
boot_pi_pass=$(grep pi_pass $BOOT_CONFIG | cut -f2- -d '=')

if [ -n "$boot_ssid" ] && [ -n "$boot_psk" ]; then
	cat > /etc/wpa_supplicant/wpa_supplicant.conf << EOF
update_config=1
ctrl_interface=/var/run/wpa_supplicant
country=us
ap_scan=1

network={
    ssid="$boot_ssid"
    psk="$boot_psk"
}
EOF
fi

cur_hostname=$(hostname)
if [ -n "$boot_hostname" ] && [ "$cur_hostname" != "$boot_hostname" ]; then
	echo "$boot_hostname" > /etc/hostname
	sed -i "s/$cur_hostname/$boot_hostname/g" /etc/hosts
	hostname $boot_hostname
	/etc/init.d/networking restart	
fi

if [ -n "$boot_samba" ]; then
	samba_enabled=0
	systemctl is-enabled smbd
	if [ $? -eq 0 ]; then
		samba_enabled=1
	fi
	if [ "$boot_samba" == "on" ]; then
		if [ $samba_enabled -eq 0 ]; then
			systemctl enable smbd
			systemctl start smbd
		fi
	else
		if [ $samba_enabled -eq 1 ]; then
			systemctl disable smbd
			systemctl stop smbd
		fi
	fi
fi

if [ -n "$boot_rsync" ]; then
	sed -i "s/^rsync_enabled=.*/rsync_enabled=$boot_rsync/g" $CONF_FILE
fi
if [ -n "$boot_rsync_url" ]; then
	sed -i "s/^rsync_url=.*/rsync_url=$boot_rsync_url/g" $CONF_FILE
fi
if [ -n "$boot_rsync_user" ]; then
	sed -i "s/^rsync_user=.*/rsync_user=$boot_rsync_user/g" $CONF_FILE
fi
if [ -n "$boot_rsync_pass" ]; then
	sed -i "s/^rsync_pass=.*/rsync_pass=$boot_rsync_pass/g" $CONF_FILE
	sed -i "s/^rsync_pass=.*/rsync_pass=/g" $BOOT_CONFIG
fi
if [ -n "$boot_rsync_cron" ]; then
	crontab -l >/tmp/ctab.tmp 2>/dev/null
	grep usb_rsync /tmp/ctab.tmp
	if [ $? -eq 0 ]; then
		sed -i "s:.*usb_rsync:$boot_rsync_cron /usr/local/bin/usb_rsync:"
	else
		echo "$boot_rsync_cron /usr/local/bin/usb_rsync" >> /tmp/ctab.tmp 
	fi
	cat /tmp/ctab.tmp | crontab -
	rm /tmp/ctab.tmp
fi
if [ -n "$boot_rsync_delete" ]; then
	sed -i "s/^rsync_delete=.*/rsync_delete=$boot_rsync_delete/g" $CONF_FILE
fi
if [ -n "$boot_auto_purge" ]; then
	sed -i "s/^auto_purge=.*/auto_purge=$boot_auto_purge/g" $CONF_FILE
fi
if [ -n "$boot_auto_purge_max_days" ]; then
	sed -i "s/^auto_purge_days=.*/auto_purge_days=$boot_auto_purge_max_days/g" $CONF_FILE
fi
if [ -n "$boot_web_control" ]; then
	web_enabled=0
	systemctl is-enabled apache2
	if [ $? -eq 0 ]; then
		web_enabled=1
	fi
	if [ "$boot_web_control" == "on" ]; then
		if [ $web_enabled -eq 0 ]; then
			systemctl enable apache2
			systemctl start apache2
		fi
	else
		if [ $web_enabled -eq 1 ]; then
			systemctl disable apache2
			systemctl stop apache2
		fi
	fi
fi
if [ -n "$boot_pi_pass" ]; then
	echo "$boot_pi_pass" | sed 's/.*/\0\n\0/' | passwd pi
	sed -i "s/^pi_pass=.*/pi_pass=/g" $BOOT_CONFIG
fi

