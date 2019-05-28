#!/bin/bash
echo "Content-type: text/html"
echo
result=$(sudo /usr/local/bin/usb_stop 2>&1)
if [ $? -ne 0 ];
then
	result=$(echo $result | sed ':a;N;$!ba;s/\n/<br>/g')
	echo "Failed to execute: $result<br>"
fi
if [ -e /run/usb_storage.run ]; then
	echo "USB Storage Running..."
else
	echo "USB Storage Stopped..."
fi

