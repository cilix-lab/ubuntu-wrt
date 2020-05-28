# Linux kernel build notes

## Prerequisites

```
# Get everything up-to-date
sudo apt-get update && sudo apt-get upgrade

# Install build dependencies
sudo apt-get install autoconf bison debootstrap dkms flex gcc-arm-none-eabi git libelf-dev libiberty-dev libncurses5-dev libncursesw5-dev libpci-dev libssl-dev libudev-dev openssl qemu-user-static u-boot-tools
```

Update `ubuntu-wrt` and submodules with:

```
git pull && git submodule foreach git pull origin master
```

Clone the `linux-kernel` repository into your working folder:

```
# Linux kernel - stable
cd ..
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
```

## Build the kernel

Go to the `linux-kernel` folder and checkout:

```
cd linux
git checkout tags/v4.19.124 -b 4.19.124-1
```

Tasks before building:

```
# Merge files
../ubuntu-wrt/scripts/merge -s ../ubuntu-wrt/linux-4.19.124 -t ./ -i

# Put correct mwlwifi Makefile in place
mv -f drivers/net/wireless/marvell/mwlwifi/Makefile.kernel drivers/net/wireless/marvell/mwlwifi/Makefile

# Apply ValCher1961's patches
cat ../ubuntu-wrt/patches/kernel-4.19.X/mvdrv.patch | patch -p1
cat ../ubuntu-wrt/patches/kernel-4.19.X/rango.patch | patch -p1
cat ../ubuntu-wrt/patches/kernel-4.19.X/regfree.patch | patch -p1

# Configure the kernel
export ARCH=arm
export CROSS_COMPILE=arm-none-eabi-
export LOCALVERSION="-wrt$(git branch | grep ^\* | cut -d '-' -f2)"
make menuconfig

# Commit
rm README.md
git add drivers/net/wireless/marvell/mwlwifi/
git commit -a -m "mwlwifi update"
```

Copy `regulatory.bin` to `/lib/firmware`:

```
sudo cp /lib/crda/regulatory.bin /lib/firmware
```

## Building the kernel

```
# Build
make -j2 modules
make -j2 zImage
make -j2 dtbs

# Merge DTB into zImage
cp arch/arm/boot/zImage zImage; cat arch/arm/boot/dts/armada-385-linksys-rango.dtb >> zImage

# Make u-boot image
mkimage -A arm -O linux -T kernel -C none -a 0x200000 -e 0x200000 -n "linux" -d zImage uImage
cp -vf uImage ../ubuntu-wrt/base/system/boot/uimage-4.19.124-wrt1

# Remove contents in folders in base system
rm -r ../ubuntu-wrt/base/system/lib/{firmware,modules}
mkdir -p ../ubuntu-wrt/base/system/lib/firmware/{mwlwifi,mrvl}

# Copy firmware
cp -vf drivers/net/wireless/marvell/mwlwifi/bin/firmware/88W8964.bin ../ubuntu-wrt/base/system/lib/firmware/mwlwifi/
cp -vf /lib/firmware/mrvl/sd8887_uapsta.bin ../ubuntu-wrt/base/system/lib/firmware/mrvl/

# Install modules
make ARCH=arm CROSS_COMPILE=arm-none-eabi- LOCALVERSION="-wrt$(git branch | grep ^\* | cut -d '-' -f2)" INSTALL_MOD_PATH=../ubuntu-wrt/base/system modules_install
rm ../ubuntu-wrt/base/system/lib/modules/4.19.124-wrt1/{build,source}
```
