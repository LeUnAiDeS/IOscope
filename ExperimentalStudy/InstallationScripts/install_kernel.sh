#!/bin/bash

# Copyright (c) PLUMgrid, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

set -ex

VER=4.9.0-040900rc6
PREFIX=http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.9-rc6
REL=201611201731
wget -q ${PREFIX}/linux-headers-${VER}-generic_${VER}.${REL}_amd64.deb
wget -q ${PREFIX}/linux-headers-${VER}_${VER}.${REL}_all.deb
wget -q ${PREFIX}/linux-image-${VER}-generic_${VER}.${REL}_amd64.deb
dpkg -i linux-*${VER}.${REL}*.deb
rm -f *.deb

#reinstall grub
apt-get -y update; sudo apt-get -y install --reinstall grub
update-grub -y





