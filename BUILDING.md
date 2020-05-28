# Building UbuntuWRT Root

This folder contains all files neccesary to run the base system.

## Prepairing USB thumb

The USB thumb drive should have at least one partition 5 GB or up for the base system. Partition your drive with `fdisk` or similar. Then, format your partition with:

```
# Considering your partition is /dev/sdb1
sudo mkfs -t ext4 -O ^64bit -L system /dev/sdb1
```

## Updating built-in software

`cd` into your work folder and do:

```
# DNScrypt-proxy 2
# Get latest release link from:
# https://github.com/DNSCrypt/dnscrypt-proxy/releases
wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.42/dnscrypt-proxy-linux_arm-2.0.42.tar.gz
tar -xf dnscrypt-proxy-linux_arm-2.0.42.tar.gz
cp -vf ./linux-arm/dnscrypt-proxy ./ubuntu-wrt/root/usr/bin/dnscrypt-proxy
```

## Creating the RootFS

```
# Create chroot
export CHROOT=/srv/chroot/ubuntu-wrt
sudo mkdir -p $CHROOT
sudo debootstrap --foreign --no-check-gpg --arch=armhf focal $CHROOT http://ports.ubuntu.com/

# Copy qemu
sudo cp /usr/bin/qemu-arm-static $CHROOT/usr/bin/

# Install base system
sudo chroot $CHROOT
/debootstrap/debootstrap --second-stage

# Mounts
mount -t proc proc proc/
mount -t sysfs sys sys/
mount -t tmpfs tmp tmp/

# Set root password
passwd

# apt
echo "deb http://ports.ubuntu.com/ubuntu-ports focal multiverse" >> /etc/apt/sources.list
echo "deb http://ports.ubuntu.com/ubuntu-ports focal restricted" >> /etc/apt/sources.list
echo "deb http://ports.ubuntu.com/ubuntu-ports focal universe" >> /etc/apt/sources.list
```

Install necessary packages:

```
apt-get update
apt-get install binutils bridge-utils bsdmainutils curl dbus dnsmasq dnsutils hostapd iproute2 iptables iw mtd-utils openssh-server pciutils python3-dev python3-pip samba-common samba-common-bin u-boot-tools usbutils vim vlan wpasupplicant wireless-tools
```

To disable `netplan` in favor of `ifupdown`:

```
apt-get install net-tools ifupdown

# Disable netplan
rm /etc/systemd/system/multi-user.target.wants/networkd-dispatcher.service
```

In case you go with `netplan`, **do not install** `ifupdown`.

Disable services for first boot:

```
# Will be enabled by rc.local
# Disable hostapd.service.
rm /etc/systemd/system/multi-user.target.wants/hostapd.service

# Disable dnsmasq
rm /etc/systemd/system/multi-user.target.wants/dnsmasq.service
```

Disable `systemd-resolved`:

```
rm /etc/resolv.conf /etc/systemd/system/multi-user.target.wants/systemd-resolved.service /etc/systemd/system/dbus-org.freedesktop.resolve1.service
echo -e 'nameserver 127.0.0.1\nsearch local' > /etc/resolv.conf
```

Remove ssh keys and disable `openssh-server`:

```
# Remove openssh keys and disable sshd
# Should be reconfigured and enabled on first run
rm /etc/ssh/ssh_host* /etc/systemd/system/multi-user.target.wants/ssh.service /etc/systemd/system/sshd.service
```

Cleanup:

```
# Remove journal folder so it logs to tmpfs
rm -r /var/log/journal

# Autoremove and clean
apt-get autoremove
apt-get clean
rm -r /var/lib/apt/lists/*

# Unmount
umount /proc
umount /sys
umount /tmp

rm -f /root/.bash_history; history -c; exit
```

Now you can prepare the target partition `system`. If mounted in `/mnt/system`:

```
# Copy chroot to target
sudo sh -c "tar -cf- -C $CHROOT . | tar -xvf- -C /mnt/system"

# Merge filesystems
sudo ./scripts/merge -s ./root -t /mnt/system

# Create uimage symlink for booting
sudo bash -c 'cd /mnt/system/boot && ln -s uimage-4.19.124-wrt1 uimage'
```
