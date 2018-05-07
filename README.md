# Ubuntu WRT
Ubuntu distribution based on 18.04 Bionic Beaver for Linksys WRT3200ACM router.  

ROOTFS: [ubuntu-wrt_18.04_4.14.32-wrt1.tar.xz](http://www.mediafire.com/file/h9bv623v96qb67t/ubuntu-wrt_18.04_4.14.32-wrt1.tar.xz)  
ROOTFS (mirror): [ubuntu-wrt_18.04_4.14.32-wrt1.tar.xz (mirror)](https://wrt.hinrichs.io/downloads/18.04/ubuntu-wrt_18.04_4.14.32-wrt1.tar.xz)  
Firmware: [wrt3200acm_4.14.32-wrt1.bin](http://www.mediafire.com/file/oh2x0vrz476b2t4/wrt3200acm_4.14.32-wrt1.bin)  
Firmware (mirror): [wrt3200acm_4.14.32-wrt1.bin (mirror)](https://wrt.hinrichs.io/downloads/18.04/wrt3200acm_4.14.32-wrt1.bin)  

## Features
* Dnsmasq for DHCP and DNS services.
* [SQM-scripts](https://github.com/tohojo/sqm-scripts) for traffic shapping. Check sample configuration in /etc/sqm. Kernel has been compiled with [CAKE](https://www.bufferbloat.net/projects/codel/wiki/Cake/) support.
* PPoE setup helper scripts `/scripts/dsl_pppoe.sh`.
* Script to setup Samba Active Directory Domain Controller `/scripts/samba-ad-dc.sh`.
* hostapd 2.6 and wpa_supplicant 2.6 with KRACK vulnerability fix.
* mwlwifi 10.3.4.0-20180330 at commit [fcaea79](https://github.com/kaloz/mwlwifi/commit/fcaea79ad33d6ae3c381d9e96bf77d6870ca8e79).

## Defaults
The default wireless configuration is:  

* 2.4GHz SSID: UbuntuWRT_2.4GHz
* 5GHz SSID: UbuntuWRT_5GHz

Both networks are open, so you should set the password right away.  

The default login:  

* Hostname: WRT
* Domain: local
* User: root
* Password: admin

## Updates
When updates are available, they will be pushed to the repository as the "linux-image" package which is already installed in the latest ROOTFS and contains all kernel modules and firmware image. The update will verify that you are updating "linux-image" in a WRT3200ACM router and proceed with flashing the firmware.  
The repository contains updates and some packages compiled specifically for the WRT3200ACM router.  

## Changelog
### 18.04
* Updated base system to Ubuntu 18.04 Bionic Beaver.
* Removed ISC-DHCP-Server and BIND9 in favour of dnsmasq.
* Added script to setup Samba Active Directory Domain Controller.
* Updated mainline kernel to 4.14.32.
* Updated mwlwifi to 10.3.4.0-20180330 at commit [fcaea79](https://github.com/kaloz/mwlwifi/commit/fcaea79ad33d6ae3c381d9e96bf77d6870ca8e79).

### 18.01
* Reverted back to 16.04 Xenial for LTS.
* Implemented DSA switch.
* Fixed interface configurations. Now booting takes only seconds.
* Back to mainline kernel. Current version is 4.14.13.
* Implemented ValCher1961's [region free patch](https://github.com/ValCher1961/McDebian_WRT3200ACM), so you can now set your region properly.

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

If you find any issues with this release, please open an issue.  

# Important Notice
* This works on WRT3200ACM. No tests have been done on any other Linksys' WRT routers.  
* You must compile hostapd-2.6 and wpa_supplicant-2.6 for rootfs if you're building your own. \* (git://w1.fi/srv/git/hostap.git)  
* To be able to use sch_cake, iproute2 with cake support needs to be compiled. \* (git://kau.toke.dk/cake/iproute2)  

\* Packages available through UbuntuWRT repository.  

## To understand more about the development of this project, follow the original thread on McDebian:
[Linksys WRT1900AC, WRT1900ACS, WRT1200AC and WRT3200ACM Router Debian Implementation](https://www.snbforums.com/threads/linksys-wrt1900ac-wrt1900acs-wrt1200ac-and-wrt3200acm-router-debian-implementation.28394/)
