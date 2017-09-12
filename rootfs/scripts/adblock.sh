#!/bin/bash

. $(dirname $0)/functions.sh

if [ -z "$1" ] || [ "$1" != "noninteractive" ]; then
	echo "This script will download a list of ad servers and create and setup a BIND9 zones file to block them."
	! ask "Do you wish to continue?" "y" && exit 0
fi

# BIND9 zones
echo "Fetching BIND zones file... "
wget "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=bindconfig&showintro=0&mimetype=plaintext" -O - 2> /dev/null | cat - | sed 's/null.zone.file/\/etc\/bind\/db.empty/g' > /etc/bind/zones.null

if ! cat /etc/bind/named.conf.local | grep -q 'include "/etc/bind/zones.null";'; then
	cp -f /etc/bind/named.conf.local /etc/bind/named.conf.local.old
	echo 'include "/etc/bind/zones.null";' >> /etc/bind/named.conf.local
fi

echo -n "Reloading BIND9... "
/usr/sbin/rndc reload > /dev/null 2>&1 && echo "OK" || echo "Failed"

echo "Done!"
echo "You can call this script periodically with cron to keep the adblock list updated. Just call this script with the \"noninteractive\" tag:"
echo "$(pwd -P)/$(basename $0) noninteractive"

exit 0
