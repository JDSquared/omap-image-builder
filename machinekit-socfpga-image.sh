#!/bin/bash
time=$(date +%Y-%m-%d)
DIR="$PWD"
archive="xz -z -8 -v"

# run the whole sausage

./RootStock-NG.sh -c machinekit-debian-jessie-socfpga

buildname="debian-8.4-mksocfpga-armhf-${time}"

cd "deploy/${buildname}"

sudo ./setup_sdcard.sh --img-4gb ${buildname} \
     --dtb socfpga-de0-nano \
     --kernel 3.10.37-ltsi-rt37-05841-g81c6be3 \
     --rootfs_label rootfs \
     --hostname mksocfpga

bmaptool create ${buildname}-4gb.img >${buildname}-4gb.bmap

#${archive} ${buildname}-4gb.img && sha256sum ${buildname}-4gb.img.xz > ${buildname}-4gb.img.xz.sha256sum
