#!/bin/bash

. $(dirname $0)/functions.sh

pre_check() {

if [ -z "$(hostname -d)" ]; then
  echo "No FQDN is setup. Please, provide a FQDN before setting up Samba AD DC."
  return 1
fi

}

setup_addc() {

# Before we start, make sure we can fetch dhcp-dyndns.sh
[ ! -d /usr/local/bin ] mkdir -p /usr/local/bin
wget -O "/usr/local/bin/dhcp-dyndns.sh" "https://github.com/cilix-lab/ubuntu-wrt/raw/master/samba-ddns-updates/usr/local/bin/dhcp-dyndns.sh" || return 2
chmod +x /usr/local/bin/dhcp-dyndns.sh

# Install packages
apt-get install -y isc-dhcp-server
apt-get install -y acl attr build-essential docbook-xsl gdb krb5-user ldb-tools libacl1-dev libattr1-dev libblkid-dev libbsd-dev libcups2-dev libgnutls28-dev libldap2-dev libpam0g-dev libpopt-dev libreadline-dev pkg-config python-dev python-dnspython samba smbclient winbind

# Stop newly installed services
systemctl stop isc-dhcp-server
systemctl stop smbd
systemctl stop nmbd
systemctl stop samba-ad-dc
systemctl stop winbind

# Stop conflicting services
systemctl stop dnsmasq

# Backup default config file
cp /etc/samba/smb.conf /etc/samba/smb.conf-dpkg && rm /etc/samba/smb.conf
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf-dpkg

# Start Samba
systemctl start samba-ad-dc

# Get IP and Domain Provision
#echo "INFO: If you have any doubts, just use default value."
#BR0_IP=`ip addr show br0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f1`
#samba-tool domain provision --use-rfc2307 --dns-backend="SAMBA_INTERNAL" --server-role="dc" --host-ip="$BR0_IP" --interactive || return 3

BR0_IP=`ip addr show br0 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f1`
HOSTNAME=`hostname`
REALM=`hostname -d`
REALM=${REALM^^}
DOMAIN=`echo $REALM | cut -d '.' -f1`
PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32}`
cat <<EOF
INFO: If you have any doubts, just use default value.
IP Address: $BR0_IP
Hostname: $HOSTNAME
Realm: $REALM
Domain: $DOMAIN
EOF
samba-tool domain provision --use-rfc2307 --dns-backend="SAMBA_INTERNAL" --server-role="dc" --domain="$DOMAIN" --realm="$REALM" --host-name="$HOSTNAME" --host-ip="$BR0_IP" --adminpass="$PASSWORD" || return 3

# Add custom config to Samba's smb.conf
for line in 'interfaces = lo br0' 'bind interfaces only = yes' 'printing = CUPS' 'printcap name = /dev/null' 'tls enabled  = yes' 'tls keyfile  = tls/key.pem' 'tls certfile = tls/cert.pem' 'tls cafile   = tls/ca.pem'; do
  sed -i '/\[global\]/a '"$line" /etc/samba/smb.conf
done
sed -i 's/dns forwarder = .*/dns forwarder = 127.0.2.1/' /etc/samba/smb.conf

# Get Kerberos config from Domain Provision
cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Restart Samba
systemctl restart samba-ad-dc

# Change Administrator password
while true; do
  read -ep "Enter password for Administrator account: " NEWPASS1
  read -ep "Confirm Administrator password: " NEWPASS2
  if [ "$NEWPASS1" = "$NEWPASS2" ]; then
    NEWPASS="$NEWPASS1"
    unset NEWPASS1
    unset NEWPASS2
    break
  else
    echo "Passwords don't match. Try again."
  fi
done

samba-tool domain passwordsettings set --complexity=off
samba-tool user setpassword --filter=samaccountname=Administrator --newpassword="$NEWPASS" -UAdministrator --password="$PASSWORD"
samba-tool user setexpiry Administrator --noexpiry

# Now let's setup DHCP DDNS
# Create DHCPd's user
DHCPDPASS=`< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-256}`
echo "$DHCPDPASS" > /etc/dhcp/dhcpduser.pass
chown dhcpd:dhcpd /etc/dhcp/dhcpduser.pass
chmod 400 /etc/dhcp/dhcpduser.pass
samba-tool user create dhcpduser "$DHCPDPASS" --description="Unprivileged user for TSIG-GSSAPI DNS updates via ISC DHCP server"
samba-tool user setexpiry dhcpduser --noexpiry
samba-tool group addmembers DnsAdmins dhcpduser
samba-tool domain exportkeytab --principal=dhcpduser@"$REALM" /etc/dhcp/dhcpduser.keytab
chown dhcpd:dhcpd /etc/dhcp/dhcpduser.keytab
chmod 400 /etc/dhcp/dhcpduser.keytab

# Add DDNS config to /etc/dhcp/dhcpd.conf
cat <<'EOF' >> /etc/dhcp/dhcpd.conf
on commit {
  set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
  set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
  set ClientDHCID = binary-to-ascii(16, 8, ":", hardware);
  set ClientName = pick-first-value(option host-name, config-option-host-name, client-name, noname);
  log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ", ClientName));
  execute("/usr/local/bin/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID, ClientName);
}

on release {
  set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
  set ClientDHCID = binary-to-ascii(16, 8, ":", hardware);
  log(concat("Release: IP: ", ClientIP));
  execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID);
}

on expiry {
  set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
  # cannot get a ClientMac here, apparently this only works when actually receiving a packet
  log(concat("Expired: IP: ", ClientIP));
  # cannot get a ClientName here, for some reason that always fails
  execute("/usr/local/bin/dhcp-dyndns.sh", "delete", ClientIP, "", "0");
}
EOF

# OK, if we've made it so far, let's start Samba4 and create the reverse zone
POS=0; unset REVERSE
for n in `echo "$BR0_IP" | tr '.' ' '`; do
  POS=$((POS+1))
  [ $POS -eq 4 ] && continue
  REVERSE="$n.$REVERSE"
done
REVERSE="$REVERSE""in-addr.arpa"
echo "Let's create the reverse lookup zone."
samba-tool dns zonecreate localhost "$REVERSE" -UAdministrator --password="$NEWPASS"

# Now let's add the reverse lookup for the host
samba-tool dns add localhost "$REVERSE" 1 PTR `hostname -f` -UAdministrator --password="$NEWPASS"

# Return successfully
unset NEWPASS DHCPDPASS
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

# Enable all
systemctl enable isc-dhcp-server
systemctl enable smbd
systemctl enable nmbd
systemctl enable samba-ad-dc
systemctl enable winbind

if ask "You should now reboot. Do you wish to do it now?" "y"; then
  reboot
fi

}

error_exit() {

echo "Something wen't wrong."
exit $1

}

echo "This script will setup Samba4 Active Directory Domain Controller."
echo "dnsmasq will be removed in favour of Samba4 DNS and ISC-DHCP-Server."
echo "If you have a custom setup, backup before proceding."
echo "The setup will be interactive."
if ask "Do you wish to continue?"; then
  pre_check && setup_addc && remove_dnsmasq && clean_up || error_exit $?
fi

exit 0
