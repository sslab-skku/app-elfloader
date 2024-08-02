#!/bin/bash

set -eux

OUT_ISO=kernel.iso
UNIKRAFT_DIR=$(realpath ../../unikraft)
root=$(pwd)
# DEFCONFIG=$(realpath ./obfusos_defconfig)
DEFCONFIG=$(realpath ./sev_virtio)

# Source the build config
#
# UK_DEFCONFIG=$DEFCONFIG make defconfig
. .config
UK_APP=$CONFIG_UK_DEFNAME
CMD_LINE=${UK_APP}.cmdl
BINARY=build/${UK_APP}_qemu-x86_64

# DYN_APP=helloworld
# DYN_APP=a.out
DYN_APP=$1
echo "Building $UK_APP"

# Update config accordingly

# Prepare cmdl
rm -rf $CMD_LINE
# if [ ! -f $CMD_LINE ]; then
# LD_DEBUG=all
# echo "$UK_APP env.vars=[ LD_LIBRARY_PATH=/lib/x86_64-linux-gnu/ LD_SHOW_AUXV=1 LD_BIND_NOW=1 LD_DEBUG=all  ]  netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- $DYN_APP -cCOM.DAT" >$CMD_LINE
echo "$UK_APP env.vars=[ LD_LIBRARY_PATH=/lib/x86_64-linux-gnu/ LD_SHOW_AUXV=1 LD_BIND_NOW=1 ]  netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 -- $DYN_APP -cCOM.DAT" >$CMD_LINE
# fi

# Build initrd cpio file
mkdir -p fs0

cp -rf prebuilt/$DYN_APP/* fs0

pushd fs0
find -depth -print | tac | bsdcpio -o --format newc >../fs0.cpio
popd

. .config
UK_APP=$CONFIG_UK_DEFNAME
CMD_LINE=${UK_APP}.cmdl
BINARY=build/${UK_APP}_qemu-x86_64
# Finally, build the image
#
make -j32
rm -rf $OUT_ISO
sudo $UNIKRAFT_DIR/support/scripts/mkukimg -f iso -i fs0.cpio -k $BINARY -b ukefi -a X64 -c $CMD_LINE -o $OUT_ISO
