#!/bin/bash
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
echo "Content-type: text/html"
echo ""
data=$(cat -)
data=$(echo $data | sed 's/&/\n/g')
sudo mv /boot/teslacam.conf /boot/teslacam.conf.bak
echo "$data"
while read -r line; do
	key=$(echo $line | cut -f 1 -d '=')
	val=$(echo $line | cut -f 2 -d '=')
	val=$(urldecode "$val")
	echo "$key=$val" | sudo tee -a /boot/teslacam.conf >/dev/null
done <<< "$data"
sudo /usr/local/bin/usb_update_config.sh
echo "Done."
