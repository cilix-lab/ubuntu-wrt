#!/bin/bash

ACTION="$1"
IP="$2"
DHCID="$3"
NAME="$4"

/usr/local/bin/dhcp-dyndns.sh "$ACTION" "$IP" "$DHCID" "$NAME" &

exit 0
