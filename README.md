# Ubuntu WRT
Ubuntu Xenial 16.04.2 for Linksys WRT3200ACM router.  
Current version is UbuntuWRT 17.08.2.  

## 1. Introduction
This project intends to keep an updated distribution of Ubuntu for the Linksys WRT3200ACM wireless router.

## 2. Features
* Chrooted BIND9 DNS server for local network with Dynamic DNS enabled.  
* ISC-DHCP-Server.  
* [SQM-scripts](https://github.com/tohojo/sqm-scripts) for traffic shapping. Check sample configuration in /etc/sqm. Kernel has been compiled with [CAKE](https://www.bufferbloat.net/projects/codel/wiki/Cake/) support.  
* Adblock and other helper scripts.  
* hostapd 2.6 and wpa_supplicant 2.6.  
* dibbler-client and dibbler-server for DHCPv6 support.  
* mwlwifi 10.3.4.0-20170810 at commit [9a6db69](https://github.com/kaloz/mwlwifi/commit/9a6db695f17c0c9ec5d4602afc9c36290c3bdea1).  

## 3. The easy way

### 3.1. Get the ROOTFS (17.08.1)
First, download the ROOTFS from [here](http://www.mediafire.com/file/wq9c8ufszducfwc/ubuntu-wrt_17.08.1_rootfs.tar.bz2) and extract the archive to an ext4 formatted USB thumb. Preferably, opt for a USB 3.0 thumb, since it will considerably improve the system's performance over USB 2.0.  

### 3.2. Get the firmware (17.08.1)
Get the firmware image from [here](http://www.mediafire.com/file/nznfls2k1ba72nz/ubuntu-wrt_17.08.1.bin) and just flash it to your router as you would with any other firmware image, according to your current firmware (stock, OpenWRT/LEDE, DD-WRT, etc.).  

### 3.3. Booting
Just plug in the ROOTFS USB thumb, start your router and enjoy!  
In it's first boot, the router will finish some tasks and reboot, so give it time.  

### 3.4.Updating to 17.08.2
Download the modules update package from [here](http://www.mediafire.com/file/45he6g1jc6emh61/linux-modules_17.08.2-0_armhf.deb) and the firmware update from [here](https://www.mediafire.com/file/55a285t7aa954j9/ubuntu-wrt_17.08.2.img).  
First install the `linux-modules_17.08.2-0_armhf.deb` package in a CHROOT environment or on the already booted router. This will install all 17.08.2 modules.  
Once the modules are installed, you can flash the new firmware `ubuntu-wrt_17.08.2.img` to the router.  

```
# copy file to router  
scp linux-modules_17.08.2-0_armhf.deb root@ubuntuwrt.local:~/  
scp ubuntu-wrt_17.08.2.img root@ubuntuwrt.local:~/  

# install modules  
dpkg -i ~/linux-modules_17.08.2-0_armhf.deb  

# erase flash
flash_erase /dev/mtd5 0 0  
flash_erase /dev/mtd6 0 0  
flash_erase /dev/mtd7 0 0  
flash_erase /dev/mtd8 0 0  

# write new firmware  
nandwrite -p /dev/mtd5 ~/ubuntu-wrt_17.08.2.img  
nandwrite -p /dev/mtd7 ~/ubuntu-wrt_17.08.2.img  
```

### 3.5. Defaults
The default wireless configuration is:  

* 2.4GHz SSID: UbuntuWRT_2.4GHz  
* 5GHz SSID: UbuntuWRT_5GHz  

Both networks are open, so you should set the password right away.  

The default login:  

* Hostname: ubuntuwrt  
* Domain: local  
* User: root  
* Password: admin  

### 3.6. Setting it up
You can setup your router as you would with an Ubuntu headless server.  

There are a couple helper scripts in "/scripts", which will help you setup a PPPoE connection and/or enable the Marvell DSA switch.  

Files you might want to check out:  
* /etc/network/interfaces  
* /etc/hostapd/wlan0.conf and /etc/hostapd/wlan1.conf  
* /etc/dhcp/dhcpd.conf  

To enable DFS channels, be sure to edit the REGDOMAIN in "/etc/default/crda" and change it in hostapd config ("/etc/hostpad").  

## 4. The hard way

### 4.1. How to compile the kernel
First, you have to get the Linux Kernel from Ubuntu. For the current commit, Ubuntu-lts-4.10.0-9.11_16.04.2 was used.

```
# Get kernel from ubuntu  
git clone git://kernel.ubuntu.com/ubuntu/ubuntu-xenial.git  

# Checkout  
cd ubuntu-xenial; git checkout Ubuntu-lts-4.10.0-9.11_16.04.2  
cd ..  

# Clone this repository  
git clone https://github.com/cilix-lab/ubuntu-wrt.git  

# Copy all files in the ubuntu-xenial-4.10.0-9.11_16.04.2 folder to the linux kernel folder  
cp -rf ubuntu-wrt/ubuntu-xenial-4.10.0-9.11_16.04.2/* ubuntu-xenial/  
```

Note: You can now use the merge tool provided. Just go to the root folder of this git and:  
`./merge -s ubuntu-xenial -t ../ubuntu-xenial -i`  
Provided you cloned the ubuntu kernel to ../ubuntu-xenial.  

That's it! You can now compile the kernel. Remember to set the proper environment variables before compiling modules, dtbs and zImage:  

```
export ARCH=arm  
export CROSS_COMPILE=arm-none-eabi-  
```

### 4.2. ROOTFS
The rootfs folder contains all modified files that you need to add to a minimal ARM installation of Ubuntu. You should set a proper chroot environment:  

```
debootstrap --foreign --no-check-gpg --arch=armhf xenial /srv/chroot/ubuntu-wrt http://ports.ubuntu.com/  
cp /usr/bin/qemu-arm-static /srv/chroot/ubuntu-wrt/usr/bin/  
chroot /srv/chroot/ubuntu-wrt  
/debootstrap/debootstrap --second-stage  
```

Then install all needed software and copy the modified rootfs files.

### 4.3. Configuration
* net.ifnames=0 was added to keep old kernel names for the interfaces.  
* No udev rules are needed. eth0 interface is used for the LAN and eth1 for the WAN. The wireless interfaces are mlan0 (mwifiex), wlan0 and wlan1 (mwlwifi).  

## 5. Changelog

### 17.08.2
* Updated mwlwifi firmware to version 9.3.8.

### 17.08.1
* Added adblock.sh script.  
* Fixed several configuration issues.  
* Minor bug fixes.  

### 17.08
* OpenSSH generates ssh keys on first boot.
* Changed naming scheme.  
* Removed Webmin.  
* Fixed several configuration files and removed obsolete files.  
* Added chroot to BIND9.  
* Added Dynamic DNS for name resolving.  

## 6. Roadmap
* Upgrade base system to Ubuntu 17.10 Artful Aardvark.  
* Start a wiki.  

# Important Notice
* This works on WRT3200ACM. No tests have been done on any other Linksys' WRT routers.  
* Must compile hostapd-2.6 and wpa_supplicant-2.6 for rootfs. (git://w1.fi/srv/git/hostap.git)  
* To be able to use sch_cake, iproute2 with cake support needs to be compiled. (git://kau.toke.dk/cake/iproute2)  

## Note on 17.08
There were several configuration issues in 17.08 release. They have now been resolved and UbuntuWRT works right away. Remember to wait at least 3 minutes in it's first boot, since it will boot, setup some things like SSH keys, and reboot.  

## To understand more about the development of this project, follow the original thread on McDebian:
[Linksys WRT1900AC, WRT1900ACS, WRT1200AC and WRT3200ACM Router Debian Implementation](https://www.snbforums.com/threads/linksys-wrt1900ac-wrt1900acs-wrt1200ac-and-wrt3200acm-router-debian-implementation.28394/)

