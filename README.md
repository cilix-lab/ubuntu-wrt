# Ubuntu WRT
Ubuntu Xenial 16.04.2 for Linksys WRT3200ACM router.

## 1 Introduction
This project intends to keep an updated distribution of Ubuntu for the Linksys WRT3200ACM wireless router.

## 2 How to compile the kernel
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

That's it! You can now compile the kernel. Remember to set the proper environment variables before compiling modules, dtbs and zImage:  

`export ARCH=arm`  
`export CROSS_COMPILE=arm-none-eabi-`  

## 3 ROOTFS
The rootfs folder contains all modified files that you need to add to a minimal ARM installation of Ubuntu. You should set a proper chroot environment:  

`debootstrap --foreign --no-check-gpg --arch=armhf xenial /srv/chroot/ubuntu-wrt http://ports.ubuntu.com/`  
`cp /usr/bin/qemu-arm-static /srv/chroot/ubuntu-wrt/usr/bin/`  
`chroot /srv/chroot/ubuntu-wrt`  
`/debootstrap/debootstrap --second-stage`  

Then install all needed software and copy the modified rootfs files.

## 4 Configuration
* net.ifnames=0 was added to keep old kernel names for the interfaces.  
* No udev rules are needed. eth0 interfaces is used for the LAN and eth1 for the WAN. The wireless interfaces are mlan0 (mwifiex), wlan0 and wlan1 (mwlwifi).  

# Important Notice
* This works on WRT3200ACM. No tests have been done on any other Linksys' WRT routers.  
* Must compile hostapd-2.6 and wpa_supplicant-2.6 for rootfs. (git://w1.fi/srv/git/hostap.git)  
* To be able to use sch_cake, iproute2 with cake support needs to be compiled. (git://kau.toke.dk/cake/iproute2)  

## To understand more about the development of this project, follow the original thread on McDebian:
[Linksys WRT1900AC, WRT1900ACS, WRT1200AC and WRT3200ACM Router Debian Implementation](https://www.snbforums.com/threads/linksys-wrt1900ac-wrt1900acs-wrt1200ac-and-wrt3200acm-router-debian-implementation.28394/)

