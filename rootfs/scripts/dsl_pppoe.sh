#!/bin/bash

. $(dirname $0)/functions.sh

echo "This script will help you setup a PPPoE connection on wan."
if ask "Do you wish to continue?" "y"; then
	pppoeconf wan
	echo "The following files will be modified for the new ppp0 interface:"
	echo "/etc/network/interfaces"
	echo "/etc/sysctl.conf"
	echo "/etc/iptables.rules"
	echo "/etc/ip6tables.rules"
	if ask "Do you wish to continue?" "y"; then
		sed -i 's/iface wan inet dhcp/iface wan inet manual/' /etc/network/interfaces
		sed -i '/^auto wan$/d' /etc/network/interfaces
		sed -i 's/net.ipv6.conf.wan.accept_ra=2/net.ipv6.conf.wan.accept_ra=0/' /etc/sysctl.conf
		sed -i 's/wan/ppp0/g' /etc/iptables.rules
		sed -i 's/wan/ppp0/g' /etc/ip6tables.rules
	fi
fi

exit 0
