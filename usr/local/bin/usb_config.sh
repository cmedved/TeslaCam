#!/bin/bash
run_file=/run/usb_storage.run
rsync_file=/run/usb_rsync.run
rsync_ip=192.168.1.5
rsync_module=TeslaCam/
rsync_user=TeslaCam
rsync_pass=T3slaC@m
teslacam_loc=/mnt/usb
teslacam_dev=/usb.bin
loop_dev=loop0
log_file=/var/log/teslacam.log
debug=1

LogDebug () {
	checkLogs
	if [ $debug ]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') [Debug] $*" | tee -a $log_file
	fi
}

LogInfo () {
	checkLogs
	echo "$(date '+%Y-%m-%d %H:%M:%S') [Info] $*" | tee -a $log_file
}

LogError() {
	checkLogs
	echo "$(date '+%Y-%m-%d %H:%M:%S') [Error] $*" | tee -a $log_file
}

checkLogs() {
	earliest_log=$(head -n1 /var/log/teslacam.log | cut -f1 -d ' ' | xargs -I{} date --date='{}' +"%s")
	if [ -z "$earliest_log" ]; then
		return
	fi
	cur_time=$(date +"%s")
	diff=$(expr $cur_time - $earliest_log)
	if [ $diff -gt 86400 ]; then
		mv $log_file $log_file.prev
	fi
}
