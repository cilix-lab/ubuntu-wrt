# UbuntuWRT 20.04

It's finally here! UbuntuWRT based on the latest to date Ubuntu LTS 20.04.

UbuntuWRT is Ubuntu for the Linksys WRT3200ACM router.

Lot's of changes since the last release:

- Ubuntu 20.04 LTS based.
- Linux kernel 4.19.124.
- Kernel loads from USB thumb, meaning you can leave factory firmware flashed. You must have a serial connection, though.

**This is still in** ***testing,*** **so use at your own risk.**

Release will be shared one testing is done, but you can build yourself for now.

## Features

- DNSmasq DHCP and DNS.
- DNScrypt-proxy 2 to manage your upstream DNS request securely.
- Ready for netplan (*testing*).

## Cloning

```
git clone --recursive https://github.com/cilix-lab/ubuntu-wrt.git
```

## U-Boot

To enable booting from the USB thumb, login to U-Boot over serial and do the following to boot from a USB thumb.

```
setenv nandboot 'setenv bootargs console=ttyS0,115200 root=/dev/sda1 rw rootdelay=5; usb reset; ext4load usb 0:1 $defaultLoadAddr /boot/uimage; bootm $defaultLoadAddr'

setenv altnandboot 'setenv bootargs console=ttyS0,115200 root=/dev/sda1 rw rootdelay=5; usb reset; ext4load usb 0:1 $defaultLoadAddr /boot/uimage; bootm $defaultLoadAddr'

saveenv
```

Defaults (to rollback flashed firmware):

```
setenv nandboot 'setenv bootargs console=ttyS0,115200 root=/dev/mtdblock6 ro rootdelay=1 rootfstype=jffs2 earlyprintk $mtdparts; nand read $defaultLoadAddr $priKernAddr $priKernSize; bootm $defaultLoadAddr'

setenv altnandboot 'setenv bootargs console=ttyS0,115200 root=/dev/mtdblock8 ro rootdelay=1 rootfstype=jffs2 earlyprintk $mtdparts; nand read $defaultLoadAddr $altKernAddr $altKernSize; bootm $defaultLoadAddr'

saveenv
```

## Building the Kernel

Read [linux-4.19.124/README.md](https://github.com/cilix-lab/ubuntu-wrt/blob/master/linux-4.19.124/README.md).

## Building Root

Read [BUILDING.md](https://github.com/cilix-lab/ubuntu-wrt/blob/master/BUILDING.md).
