#!/bin/bash
echo "Content-type: text/html"
echo ""
cat /boot/teslacam.conf | grep -v "^wireless_psk\|^pi_pass"
