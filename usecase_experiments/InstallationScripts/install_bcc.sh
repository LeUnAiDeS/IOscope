#!/bin/bash

# Copyright (c) PLUMgrid, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

### DEPENDENCIES
VER=trusty
echo "deb http://llvm.org/apt/$VER/ llvm-toolchain-$VER-3.7 main
deb-src http://llvm.org/apt/$VER/ llvm-toolchain-$VER-3.7 main" | \
  sudo tee /etc/apt/sources.list.d/llvm.list
wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
apt-get update

# All versions
apt-get -y install bison build-essential cmake flex git libedit-dev \
  libllvm3.7 llvm-3.7-dev libclang-3.7-dev python zlib1g-dev libelf-dev

# For Lua support
apt-get -y install luajit luajit-5.1-dev



### DOWNLOAD AND INSTALL THE REPO 
apt-get -y install unzip 
# download the repo 
wget https://github.com/iovisor/bcc/archive/master.zip
unzip master.zip 
mkdir bcc-master/build; cd bcc-master/build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make
make install
