#!/bin/sh

setup_addc() {

# Before we start, make sure we can fetch config files

# /etc/dhcp folder
mkdir -p /tmp/samba-ddns-updates/dhcp
for f in "dhcpd-update-samba-dns.conf" "dhcpd-update-samba-dns.sh" "dhcpd.conf"; do
  wget -O "/tmp/samba-ddns-updates/dhcp/$f" "https://github.com/cilix-lab/ubuntu-wrt/raw/master/samba-ddns-updates/etc/dhcp/$f" || return 1
done

# /usr/bin folder
mkdir -p /tmp/samba-ddns-updates/bin
wget -O "/tmp/samba-ddns-updates/bin/samba-dnsupdate.sh" "https://github.com/cilix-lab/ubuntu-wrt/raw/master/samba-ddns-updates/usr/bin/samba-dnsupdate.sh" || return 2

# Install packages
apt-get install -y isc-dhcp-server
apt-get install -y acl attr build-essential docbook-xsl gdb krb5-user ldb-tools libacl1-dev libattr1-dev libblkid-dev libbsd-dev libcups2-dev libgnutls28-dev libldap2-dev libpam0g-dev libpopt-dev libreadline-dev pkg-config python-dev python-dnspython samba smbclient winbind

# Stop newly installed services
/bin/systemctl stop isc-dhcp-server
/etc/init.d/samba stop
/bin/systemctl stop winbind
/bin/systemctl disable isc-dhcp-server
/bin/systemctl disable smbd
/bin/systemctl disable nmbd
/bin/systemctl disable samba-ad-dc
/bin/systemctl disable winbind

# Stop conflicting services
/bin/systemctl stop dnsmasq

# Backup default config file
cp /etc/samba/smb.conf /etc/samba/smb.conf-dpkg
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf-dpkg

# Get IP and Domain Provision
echo "INFO: If you have any doubts, just use default value."
BR0_IP=`ip addr show br0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f1`
/usr/bin/samba-tool domain provision --use-rfc2307 --use-ntvfs --dns-backend="SAMBA_INTERNAL" --server-role="dc" --host-ip="$BR0_IP" --interactive

# Add custom config to Samba's smb.conf
for line in 'interfaces = lo br0' 'bind interfaces only = yes' 'printing = CUPS' 'printcap name = /dev/null' 'tls enabled  = yes' 'tls keyfile  = tls/key.pem' 'tls certfile = tls/cert.pem' 'tls cafile   = tls/ca.pem'; do
  sed -i '/\[global\]/a '"$line" /etc/samba/smb.conf
done
sed -i 's/dns forwarder = .*/dns forwarder = 127.0.2.1/' /etc/samba/smb.conf

# Get Kerberos config from Domain Provision
cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Now let's setup DHCP DDNS
# Create DHCPd's user
DOMAIN=`cat /etc/samba/smb.conf | tr -d ' ' | grep 'realm=.*' | cut -d '=' -f2`
/usr/bin/samba-tool user create dhcpduser --description="Unprivileged user for TSIG-GSSAPI DNS updates via ISC DHCP server" --random-password
/usr/bin/samba-tool user setexpiry dhcpduser --noexpiry
/usr/bin/samba-tool group addmembers DnsAdmins dhcpduser
/usr/bin/samba-tool domain exportkeytab --principal=dhcpduser@"$DOMAIN" /etc/dhcp/dhcpduser.keytab
/bin/chown dhcpd:dhcpd /etc/dhcp/dhcpduser.keytab
/bin/chmod 400 /etc/dhcp/dhcpduser.keytab

# Now, let's put downloaded files in place and set permissions
for f in "dhcpd-update-samba-dns.conf" "dhcpd-update-samba-dns.sh" "dhcpd.conf"; do
  cp -f "/tmp/samba-ddns-updates/dhcp/$f" "/etc/dhcp/"
done
cp "/tmp/samba-ddns-updates/bin/samba-dnsupdate.sh" "/usr/bin/"
chmod +x /etc/dhcp/dhcpd-update-samba-dns.sh /usr/bin/samba-dnsupdate.sh

# OK, if we've made it so far, let's start Samba4 and create the reverse zone
POS=0; unset REVERSE
for n in `echo "$BR0_IP" | tr '.' ' '`; do
  POS=$((POS+1))
  [ $POS -eq 4 ] && continue
  REVERSE="$n.$REVERSE"
done
REVERSE="$REVERSE""in-addr.arpa"
/etc/init.d/samba start
echo "Let's create the reverse lookup zone."
/usr/bin/samba-tool dns zonecreate localhost "$REVERSE"

# Now let's add the reverse lookup for the host
/usr/bin/samba-tool dns add localhost "$REVERSE" 1 PTR `hostname -f` -UAdministrator

# Return successfully
return 0

}

remove_dnsmasq() {

# Let's remove dnsmasq
apt-get purge -y dnsmasq &&\
  apt-get autoremove -y &&\
  rm -rf /etc/dnsmasq.conf /etc/dnsmasq.d > /dev/null 2>&1

return 0

}

clean_up() {

# Remove downloaded folder
rm -r /tmp/samba-ddns-updates

# Enable all
/bin/systemctl enable isc-dhcp-server
/bin/systemctl enable smbd
/bin/systemctl enable nmbd
/bin/systemctl enable samba-ad-dc
/bin/systemctl enable winbind

if ask "You should now reboot. Do you wish to do it now?" "y"; then
  reboot
fi

}

error_exit() {

echo "Something wen't wrong, config files could not be fetched."
exit 1

}

echo "This script will setup Samba4 Active Directory Domain Controller."
echo "dnsmasq will be removed in favour of Samba4 DNS and ISC-DHCP-Server."
echo "If you have a custom setup, backup before proceding."
echo "The setup will be interactive."
if ask "Do you wish to continue?"; then
  setup_addc && remove_dnsmasq && clean_up || error_exit
fi

exit 0
