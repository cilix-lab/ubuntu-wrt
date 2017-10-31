# Ubuntu WRT
Ubuntu distribution based on Zesty 17.04 for Linksys WRT3200ACM router.  
Current version is UbuntuWRT 17.10.  

## Hostapd KRACK vulnerability
Patched hostapd and wpa_supplicant have been included in the latest ROOTFS and they have been packaged and pushed to the new UbuntuWRT repository! If you have an older UbuntuWRT release, see "Adding UbuntuWRT repository".   

## 1. Introduction
This project intends to keep an updated distribution of Ubuntu for the Linksys WRT3200ACM wireless router.

## 2. Features
* Chrooted BIND9 DNS server for local network with Dynamic DNS enabled.  
* ISC-DHCP-Server.  
* [SQM-scripts](https://github.com/tohojo/sqm-scripts) for traffic shapping. Check sample configuration in /etc/sqm. Kernel has been compiled with [CAKE](https://www.bufferbloat.net/projects/codel/wiki/Cake/) support.  
* Adblock and other helper scripts.  
* hostapd 2.6 and wpa_supplicant 2.6.  
* mwlwifi 10.3.4.0-20170810 at commit [e119077](https://github.com/kaloz/mwlwifi/commit/e119077b68d64e368cb9cc46bd364308db4289dc).  

## 3. The easy way

### 3.1. Get the ROOTFS (17.10)
First, download the ROOTFS:  
[ubuntu-wrt_zesty_17.10.tar.bz2](http://www.mediafire.com/file/b6ah55mqdk36qav/ubuntu-wrt_zesty_17.10.tar.bz2)  
[ubuntu-wrt_zesty_17.10.tar.bz2 (mirror)](https://wrt.hinrichs.io/downloads/17.10/ubuntu-wrt_zesty_17.10.tar.bz2)  
Extract the archive to an ext4 formatted USB thumb. Preferably, opt for a USB 3.0 thumb, since it will improve the system's performance considerably over USB 2.0.  

### 3.2. Get the firmware (17.10)
Get the firmware image:  
[wrt3200acm_4.10.17-37.41-0.bin](http://www.mediafire.com/file/oll4p9eudw6dawo/wrt3200acm_4.10.17-37.41-0.bin)  
[wrt3200acm_4.10.17-37.41-0.bin (mirror)](https://wrt.hinrichs.io/downloads/17.10/wrt3200acm_4.10.17-37.41-0.bin)  
Flash it to your router as you would with any other firmware image, according to your current firmware (stock, OpenWRT/LEDE, DD-WRT, etc.).  

### 3.3. Booting
Plug in the ROOTFS USB thumb after flashing, start your router and enjoy!  
In it's first boot, the router will finish some tasks (like generating SSH keys) and reboot, so give it at least 3 minutes.  

### 3.4. Defaults
The default wireless configuration is:  

* 2.4GHz SSID: UbuntuWRT_2.4GHz  
* 5GHz SSID: UbuntuWRT_5GHz  

Both networks are open, so you should set the password right away.  

The default login:  

* Hostname: ubuntuwrt  
* Domain: local  
* User: root  
* Password: admin  

### 3.5. Setting it up
You can setup your router as you would with an Ubuntu headless server.  

There are a couple helper scripts in "/scripts", which will help you setup a PPPoE connection and/or enable the Marvell DSA switch.  

Files you might want to check out:  
* /etc/network/interfaces  
* /etc/hostapd/wlan0.conf and /etc/hostapd/wlan1.conf  
* /etc/dhcp/dhcpd.conf  

To enable DFS channels, be sure to edit the REGDOMAIN in "/etc/default/crda" and change it in hostapd config ("/etc/hostpad").  

## 3.6. Updates
Updates are now easily pushed through the new UbuntuWRT repository, which is already included in APT's sources.list in the latest ROOTFS.  
When updates are available, they will be pushed to the repository as the "linux-modules" packages which is already installed in the latest ROOTFS and contains all kernel modules and firmware image. The update will verify that you are updating "linux-modules" in a WRT3200ACM router and proceed with flashing the firmware.  
The repository contains updates and some packages compiled specifically for the WRT3200ACM router.  

## 3.7. Adding UbuntuWRT repository
If you have an older release, you can add the UbuntuWRT repository to get the latest updates and packages curated for the WRT3200ACM router.  
Important! Keep in mind that this repository's packages are built with the latest UbuntuWRT in mind and they are only tested on that system, so there's no guarantee that they will work properly if you install on older releases.  

```
# Adding UbuntuWRT repository to APT's sources.list
echo "deb http://wrt.hinrichs.io/ubuntu zesty main" >> /etc/apt/sources.list

# Get the repository key
wget -qO - https://wrt.hinrichs.io/downloads/ubuntuwrt.key | apt-key add -

# Update lists
apt-get update
```

## 4. The hard way (not updated)

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

### 17.10
* New UbuntuWRT repository. Already configured in latest ROOTFS.  
* Now specially curated packages for the WRT3200ACM are provided directly through the UbuntuWRT repository.
* Upgraded base system to Ubuntu Zesty 17.04.  
* Minor bug fixes and configuration changes.  

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
* Must compile hostapd-2.6 and wpa_supplicant-2.6 for rootfs. \* (git://w1.fi/srv/git/hostap.git)  
* To be able to use sch_cake, iproute2 with cake support needs to be compiled. \* (git://kau.toke.dk/cake/iproute2)  

\* Packages available through UbuntuWRT repository.  

## To understand more about the development of this project, follow the original thread on McDebian:
[Linksys WRT1900AC, WRT1900ACS, WRT1200AC and WRT3200ACM Router Debian Implementation](https://www.snbforums.com/threads/linksys-wrt1900ac-wrt1900acs-wrt1200ac-and-wrt3200acm-router-debian-implementation.28394/)

