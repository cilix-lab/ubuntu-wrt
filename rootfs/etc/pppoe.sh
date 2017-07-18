#!/bin/bash

ask() { local q="$1"; local d=${2:-"n"}
read -p "$q [$d]: " r; r=${r:-"$d"}
while true; do
	case $r in
		y|Y|yes|Yes|yES|YES )
			return 0
			;;
		n|N|no|No|nO )
			return 1
			;;
		* )
			read -p "Not a valid answer. Try 'y' or 'n': " r
			continue
			;;
	esac
done
}

echo "This script will help you setup a PPPoE connection on eth1."
if ask "Do you wish to continue?" "y"; then
	pppoeconf eth1
	echo "The following files will be modified for the new ppp0 interface:"
	echo "/etc/network/interfaces"
	echo "/etc/sysctl.conf"
	echo "/etc/iptables.rules"
	echo "/etc/ip6tables.rules"
	if ask "Do you wish to continue?" "y"; then
		sed -i 's/iface eth1 inet dhcp/iface eth1 inet manual/' /etc/network/interfaces
		sed -i 's/net.ipv6.conf.eth1.accept_ra=2/net.ipv6.conf.eth1.accept_ra=0/' /etc/sysctl.conf
		sed -i 's/eth1/ppp0/g' /etc/iptables.rules
		sed -i 's/eth1/ppp0/g' /etc/ip6tables.rules
	fi
fi

exit 0
