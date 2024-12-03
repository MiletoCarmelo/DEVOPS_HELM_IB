#!/bin/bash

# Installation de Box64
cd /opt
git clone https://github.com/ptitSeb/box64
cd box64
mkdir build && cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
make install
cd ../..
rm -rf box64

# Installation de Box86
git clone https://github.com/ptitSeb/box86
cd box86
mkdir build && cd build
cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
make install
cd ../..
rm -rf box86

# Configuration des bibliothèques
echo "/usr/local/lib64" > /etc/ld.so.conf.d/box64.conf
echo "/usr/local/lib/i386-linux-gnu" > /etc/ld.so.conf.d/box86.conf
ldconfig