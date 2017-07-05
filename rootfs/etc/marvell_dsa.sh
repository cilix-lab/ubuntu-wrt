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

write_dsa() {
cat <<EOF > /etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

allow-hotplug eth1
iface eth1 inet manual

allow-hotplug wlan0
iface wlan0 inet manual

allow-hotplug wlan1
iface wlan1 inet manual

allow-hotplug lan1
iface lan1 inet manual

allow-hotplug lan2
iface lan2 inet manual

allow-hotplug lan3
iface lan3 inet manual

allow-hotplug lan4
iface lan4 inet manual

allow-hotplug wan
iface wan inet dhcp
	pre-up /etc/dibbler/armada-set-mac
	pre-up iptables-restore < /etc/iptables.up.rules
	pre-up ip6tables-restore < /etc/ip6tables.up.rules

auto br0
iface br0 inet static
	bridge_ports lan1 lan2 lan3 lan4 wlan0 wlan1
	address 192.168.1.1
	netmask 255.255.255.0
	network 192.168.1.0
	broadcast 192.168.1.255

EOF
}

write_default() {
cat <<EOF > /etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

allow-hotplug wlan0
iface wlan0 inet manual

allow-hotplug wlan1
iface wlan1 inet manual

allow-hotplug eth1
auto eth1
iface eth1 inet dhcp
	pre-up /etc/dibbler/armada-set-mac
	pre-up iptables-restore < /etc/iptables.up.rules
	pre-up ip6tables-restore < /etc/ip6tables.up.rules

auto br0
iface br0 inet static
	bridge_ports eth0 wlan0 wlan1
	address 192.168.1.1
	netmask 255.255.255.0
	network 192.168.1.0
	broadcast 192.168.1.255

EOF
}

enable_dsa() {
  echo "This script will enable Marvell DSA switch module and configuration."
  if ask "Do you wish to continue?" "n"; then

    # adding module load at startup
    grep -q '^mv88e6xxx$' /etc/modules || echo "mv88e6xxx" >> /etc/modules

    # interfaces
    cp -f /etc/network/interfaces /etc/network/interfaces-old &&\
      echo "Backed up /etc/network/interfaces to /etc/network/interfaces-old."
    write_dsa

    # fixing config files
    files="/etc/sysctl.conf /etc/iptables.up.rules /etc/ip6tables.up.rules /etc/ppp/peers/dsl-provider /etc/dibbler/client.conf /etc/dibbler/armada-set-mac"
    for f in $files; do
      echo -n "Modifying $f... "
      sed -i 's/eth1/wan/g' $f 2> /dev/null &&\
        echo "ok" || echo "failed"
    done

  fi
}

disable_dsa() {
  echo "This script will disable Marvell DSA switch module and configuration."
  if ask "Do you wish to continue?" "n"; then

    # adding module load at startup
    grep -q '^mv88e6xxx$' /etc/modules && sed -i '/^mv88e6xxx$/d' /etc/modules

    # interfaces
    if [ -f "/etc/network/interfaces-old" ]; then
      echo "A backed up interfaces file was found."
      if ask "Do you wish to restore it?" "y"; then
        cp -f /etc/network/interfaces-old /etc/network/interfaces &&\
          echo "Restored /etc/network/interfaces from /etc/network/interfaces-old."
      fi
    else
      write_dsa
      echo "Default interfaces file written."
    fi

    # fixing config files
    files="/etc/sysctl.conf /etc/iptables.up.rules /etc/ip6tables.up.rules /etc/ppp/peers/dsl-provider /etc/dibbler/client.conf /etc/dibbler/armada-set-mac"
    for f in $files; do
      echo -n "Modifying $f... "
      sed -i 's/wan/eth1/g' $f 2> /dev/null &&\
        echo "ok" || echo "failed"
    done

  fi
}

if lsmod | grep -q 'mv88e6xxx'; then
  echo "Marvell DSA module is not loaded."
  enable_dsa
  echo "Declared interfaces will be setup as default."
  echo "If you had custom interfaces, be sure to make necessary modifications before rebooting."
else
  echo "Marvell DSA module is loaded."
  disable_dsa
fi
