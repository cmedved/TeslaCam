#!/bin/bash
echo "Content-type: text/html"
echo
usb_status="Unknown"
if [ -e /run/usb_storage.run ]; then
	usb_status="Running"
else
	usb_status="Stopped"
fi

rsync_status="Unknown"
if [ -e /run/usb_rsync.run ]; then
	rsync_status="Running"
else
	rsync_status="Stopped"
fi

disk_usage=$(df -h | grep /dev/loop0 | grep -o "[0-9]*%" | grep -o "[0-9]*")
if [ -z "$disk_usage" ]; then
	disk_usage=-1
fi

echo "{ \"usb_status\":\"$usb_status\", \"rsync_status\":\"$rsync_status\", \"disk_usage\": $disk_usage }"
