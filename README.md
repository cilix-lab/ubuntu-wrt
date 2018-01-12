# Ubuntu WRT
Ubuntu distribution based on 16.04 Xenial for Linksys WRT3200ACM router.
Currently testing 18.01-beta.  
[Rootfs](https://wrt.hinrichs.io/downloads/18.01-beta/ubuntu-wrt_18.01_xenial-beta.tar.bz2)  
[Firmware](https://wrt.hinrichs.io/downloads/18.01-beta/wrt3200acm_4.14.13-wrt0.bin)  

Some big changes on the way.  
18.01-beta Changelog:
* Reverted back to 16.04 Xenial for LTS.  
* Implemented DSA switch.  
* Fixed interface configurations. Now booting takes only seconds.  
* Back to mainline kernel. Current version is 4.14.13.  
* Implemented ValCher1961's [region free patch](https://github.com/ValCher1961/McDebian_WRT3200ACM), so you can now set your region properly.  

If you find any issues with this release, please open an issue.  

# [Not Updated]
Ubuntu distribution based on 17.04 Zesty for Linksys WRT3200ACM router.  
Current version is UbuntuWRT 17.10.1.  

## Hostapd KRACK vulnerability
Patched hostapd and wpa_supplicant have been included in the latest ROOTFS and they have been packaged and pushed to the new UbuntuWRT repository! If you have an older UbuntuWRT release, see "3.7. Adding UbuntuWRT repository".   

## 1. Introduction
This project intends to keep an updated distribution of Ubuntu for the Linksys WRT3200ACM wireless router.

## 2. Features
* Chrooted BIND9 DNS server for local network with Dynamic DNS enabled.  
* ISC-DHCP-Server.  
* [SQM-scripts](https://github.com/tohojo/sqm-scripts) for traffic shapping. Check sample configuration in /etc/sqm. Kernel has been compiled with [CAKE](https://www.bufferbloat.net/projects/codel/wiki/Cake/) support.  
* Adblock and other helper scripts.  
* hostapd 2.6 and wpa_supplicant 2.6 with KRACK vulnerability fix.  
* mwlwifi 10.3.4.0-20170810 at commit [466368f](https://github.com/kaloz/mwlwifi/commit/466368f9454250c2bc024795600d92564553d9bb).  

## 3. The easy way

### 3.1. Get the ROOTFS (17.10.1)
First, download the ROOTFS:  
[ubuntu-wrt_zesty_17.10.1.tar.bz2](https://www.mediafire.com/file/eswojytdl7tp9ob/ubuntu-wrt_zesty_17.10.1.tar.bz2)  
[ubuntu-wrt_zesty_17.10.1.tar.bz2 (mirror)](https://wrt.hinrichs.io/downloads/17.10.1/ubuntu-wrt_zesty_17.10.1.tar.bz2)  
Extract the archive to an ext4 formatted USB thumb. Preferably, opt for a USB 3.0 thumb, since it will improve the system's performance considerably over USB 2.0.  

### 3.2. Get the firmware (17.10.1)
Get the firmware image:  
[wrt3200acm_4.10.17-40.44-0.bin](https://www.mediafire.com/file/c5l6d18ppcg9qt8/wrt3200acm_4.10.17-40.44-0.bin)  
[wrt3200acm_4.10.17-40.44-0.bin (mirror)](https://wrt.hinrichs.io/downloads/17.10.1/wrt3200acm_4.10.17-40.44-0.bin)  
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

### 3.6. Updates
Updates are now easily pushed through the new UbuntuWRT repository, which is already included in APT's sources.list in the latest ROOTFS.  
When updates are available, they will be pushed to the repository as the "linux-modules" package which is already installed in the latest ROOTFS and contains all kernel modules and firmware image. The update will verify that you are updating "linux-modules" in a WRT3200ACM router and proceed with flashing the firmware.  
The repository contains updates and some packages compiled specifically for the WRT3200ACM router.  

### 3.7. Adding UbuntuWRT repository
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

## 4. The hard way
You can compile your own kernel and create the rootfs yourself. To acomplish this, you need to get the ubuntu kernel for the desired distribution, clone this repository, and merge this repository's ubuntu-xenial/ubuntu-zesty folder according to the distro you chose, with the kernel's.  

For the rootfs, create a CHROOT environment out of the desired port of Ubuntu and install/build all necesary software. You can also choose to use UbuntuWRT repository too, following the instrucionts on "3.7. Adding UbuntuWRT repository".  

## 5. Changelog

### 17.10.1
* Updated kernel to 4.10.17-40.44-0.  
* Updated mwlwifi to commit [466368f](https://github.com/kaloz/mwlwifi/commit/466368f9454250c2bc024795600d92564553d9bb).  
* Changed network configuration to properly set eth1 MAC from script.  
* Minor fixes to some configuration files.  

### 17.10
* New UbuntuWRT repository. Already configured in latest ROOTFS.  
* Now curated packages for the WRT3200ACM are provided directly through the UbuntuWRT repository.
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
