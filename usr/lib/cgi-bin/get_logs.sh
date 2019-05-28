#!/bin/bash
echo "Content-type: text/html"
echo
cat /var/log/teslacam.log | sed ':a;N;$!ba;s/\n/<br>/g'
