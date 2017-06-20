# Ubuntu WRT
Ubuntu Xenial 16.04.2 for Linksys WRT3200ACM router.

## 1. Introduction
This project intends to keep an updated distribution of Ubuntu for the Linksys WRT3200ACM wireless router.

## 2. The easy way
Current ROOTFS and firmware are updated up to 4.10.0-9.11_16.04.2_20170617. That's Ubuntu LTS 16.04.2 Kernel v4.10.0, with everything up to date to 06/17/2017.  

### 2.1. Get the ROOTFS
First, download the ROOTFS from [here](http://www.mediafire.com/file/rjj7m00xob8qipl/ubuntu-wrt-4.10.0-9.11_16.04.2_20170617.tar.bz2) and extract the archive to an ext4 formatted USB thumb. Preferably, opt for a USB 3.0 thumb, since it will considerably improve the system's performance over USB 2.0.  

### 2.2. Get the firmware
Get the firmware image from [here](http://www.mediafire.com/file/bj7g53tdwaw3ag7/ubuntu-wrt-4.10.0-9.11_16.04.2_20170617.img) and just flash it to your router as you would with any other firmware image, according to your current firmware (stock, OpenWRT/LEDE, DD-WRT, etc.).  

### 2.3. Booting
Just plug in the ROOTFS USB thumb, start your router up and enjoy!  

The default wireless configuration is:  

* 2.4GHz SSID: Armada_2.4GHz  
* 2.4GHz Password: armada24  
* 5GHz SSID: Armada_5GHz  
* 5GHz Password: armada50  

The default login:  

* Hostname: wrt  
* User: root  
* Password: admin  

You can also login on Webmin at [http://wrt.lan](http://wrt.lan) or [http://192.168.1.1](http://192.168.1.1) with default user and password.  

The current distribution is based on a minimal Ubuntu 16.04.2 installation plus:  

* BIND9 DNS server for local network. Check configuration files in /etc/bind.  
* ISC-DHCP-Server.  
* [SQM-scripts](https://github.com/tohojo/sqm-scripts) for traffic shapping. Check sample configuration in /etc/sqm. Kernel has been compiled with [CAKE](https://www.bufferbloat.net/projects/codel/wiki/Cake/) support.  
* Webmin 1.84.  
* hostapd 2.6 and wpa_supplicant 2.6 for the wireless radios.  
* dibbler-client and dibbler-server for DHCPv6 support.  
* mwlwifi 10.3.4.0-20170606 at commit 36bc32767ed89e07c5c83036861d2fa4eb1f8629.  

## 3. The hard way

### 3.1. How to compile the kernel
First, you have to get the Linux Kernel from Ubuntu. For the current commit, Ubuntu-lts-4.10.0-9.11_16.04.2 was used.

`# Get kernel from ubuntu`  
`git clone git://kernel.ubuntu.com/ubuntu/ubuntu-xenial.git`  

`# Checkout`  
`cd ubuntu-xenial; git checkout Ubuntu-lts-4.10.0-9.11_16.04.2`  
`cd ..`  

`# Clone this repository`  
`git clone https://github.com/cilix-lab/ubuntu-wrt.git`  

`# Copy all files in the ubuntu-xenial-4.10.0-9.11_16.04.2 folder to the linux kernel folder`  
`cp -rf ubuntu-wrt/ubuntu-xenial-4.10.0-9.11_16.04.2/* ubuntu-xenial/`  

Note: You can now use the merge tool provided. Just go to the root folder of this git and:  
`./merge -s ubuntu-xenial -t ../ubuntu-xenial -i`  
Provided you cloned the ubuntu kernel to ../ubuntu-xenial.  

That's it! You can now compile the kernel. Remember to set the proper environment variables before compiling modules, dtbs and zImage:  

`export ARCH=arm`  
`export CROSS_COMPILE=arm-none-eabi-`  

### 3.2. ROOTFS
The rootfs folder contains all modified files that you need to add to a minimal ARM installation of Ubuntu. You should set a proper chroot environment:  

`debootstrap --foreign --no-check-gpg --arch=armhf xenial /srv/chroot/ubuntu-wrt http://ports.ubuntu.com/`  
`cp /usr/bin/qemu-arm-static /srv/chroot/ubuntu-wrt/usr/bin/`  
`chroot /srv/chroot/ubuntu-wrt`  
`/debootstrap/debootstrap --second-stage`  

Then install all needed software and copy the modified rootfs files.

### 3.3. Configuration
* net.ifnames=0 was added to keep old kernel names for the interfaces.  
* No udev rules are needed. eth0 interface is used for the LAN and eth1 for the WAN. The wireless interfaces are mlan0 (mwifiex), wlan0 and wlan1 (mwlwifi).  

# Important Notice
* This works on WRT3200ACM. No tests have been done on any other Linksys' WRT routers.  
* Must compile hostapd-2.6 and wpa_supplicant-2.6 for rootfs. (git://w1.fi/srv/git/hostap.git)  
* To be able to use sch_cake, iproute2 with cake support needs to be compiled. (git://kau.toke.dk/cake/iproute2)  

## To understand more about the development of this project, follow the original thread on McDebian:
[Linksys WRT1900AC, WRT1900ACS, WRT1200AC and WRT3200ACM Router Debian Implementation](https://www.snbforums.com/threads/linksys-wrt1900ac-wrt1900acs-wrt1200ac-and-wrt3200acm-router-debian-implementation.28394/)

