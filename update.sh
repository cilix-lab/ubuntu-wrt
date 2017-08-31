#!/bin/bash

ask() { local q="$1"; local d=${2:-"n"}
  read -p "$q [$d]: " r; r=${r:-"$d"}
  local i=0; while true; do
    case $r in
      y|Y|yes|Yes|yES|YES )
        return 0
        ;;
      n|N|no|No|nO )
        return 1
        ;;
      * )
        i=$((i+1))
        [ $i -le 3 ] && read -p "Not a valid answer. Try 'y' or 'n': " r || exit 1
        continue
        ;;
    esac
  done
}

workdir=$(dirname $(realpath `dirname $0`)); err=0
echo "This script will pull sources from git and update Ubuntu-WRT."
echo "Sources will be pulled within the parent directory: $workdir"
if ! ask "Do you wish to continue?" "y"; then exit 0; fi

# mwlwifi
cd "$workdir"; echo "Updating mwlwifi... "
[ ! -d ./mwlwifi ] && git clone https://github.com/kaloz/mwlwifi.git
if cd mwlwifi; then
  git pull; cd ..
  if rm -rf ubuntu-wrt/ubuntu-xenial/drivers/mwlwifi; then
    cp -r mwlwifi ubuntu-wrt/ubuntu-xenial/drivers/
    rm -rf ubuntu-wrt/ubuntu-xenial/drivers/mwlwifi/.git
    mv -f ubuntu-wrt/ubuntu-xenial/drivers/mwlwifi/Makefile.kernel ubuntu-wrt/ubuntu-xenial/drivers/mwlwifi/Makefile
    # update firmware
    rm -rf ubuntu-wrt/ubuntu-xenial/firmware/mwlwifi
    mv ubuntu-wrt/ubuntu-xenial/drivers/mwlwifi/bin/firmware ubuntu-wrt/ubuntu-xenial/firmware/mwlwifi
    rm -rf ubuntu-wrt/ubuntu-xenial/drivers/mwlwifi/bin
  else
    echo "mwlwifi driver missing. Maybe not right branch?"
  fi
else
  echo "Failed to clone mwlwifi."
  err=$((err+1))
fi

# mwifiex
cd "$workdir"; echo "Updating mwifiex firmware... "
[ ! -d ./linux-firmware ] && git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
if cd linux-firmware; then
  git pull; cd ..
  if rm -f ubuntu-wrt/ubuntu-xenial/firmware/mrvl/*; then
    cp -f linux-firmware/mrvl/sd8887_uapsta.bin ubuntu-wrt/ubuntu-xenial/firmware/mrvl/sd8887_uapsta.bin
  else
    echo "mwifiex firmware missing. Maybe not right branch?"
  fi
else
  echo "Failed to clone linux-firmware."
  err=$((err+10))
fi

# cake
cd "$workdir"; echo "Updating sch_cake... "
[ ! -d ./sch_cake ] && git clone https://github.com/dtaht/sch_cake.git
if cd sch_cake; then
  git pull; cd ..
  cp -f sch_cake/*.c sch_cake/*.h ubuntu-wrt/ubuntu-xenial/net/sched/
else
  echo "Failed to clone sch_cake."
  err=$((err+100))
fi

# wireless-regdb
cd "$workdir"; echo "Updating wireless-regdb... "
[ ! -d ./wireless-regdb ] && git clone git://git.kernel.org/pub/scm/linux/kernel/git/linville/wireless-regdb.git
if cd wireless-regdb; then
  git pull; cd ..
  cp -f wireless-regdb/db.txt ubuntu-wrt/ubuntu-xenial/net/wireless/db.txt
else
  echo "Failed to clone wireless-regdb."
  err=$((err+1000))
fi

cd "$workdir"
if [ $err == 0 ] && ask "Done. Do you wish to run ubuntu-wrt ./merge to update ubuntu-xenial sources?" "n"; then
  ubuntu-wrt/merge -s ubuntu-wrt/ubuntu-xenial -t ubuntu-xenial -i
else
  echo "There have been errors during update."
  exit $err
fi

