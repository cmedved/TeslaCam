cd "$(dirname "$0")"
source usb_config.sh

if [ "$auto_purge" != "on" ]; then
	exit 0
fi

if [ ! -e $teslacam_loc/TeslaCam ]; then
	LogError "Can't find TeslaCam directory! Tried \"$teslacam_loc/TeslaCam\""
	exit 1
fi

./usb_stop
sleep 3
find $teslacam_loc/TeslaCam -type f -mtime +$auto_purge_days -exec echo {} \;
./usb_start
