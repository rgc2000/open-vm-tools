#!/usr/bin/ksh
# Script to clean Solatis 11 pkg files build

export DESTDIR=/tmp/vmtools-build

# =======  Clean open-vm-tools

cd ../open-vm-tools
gmake distclean
cd ../solaris-build

# =======  Clean files

rm -rf "$DESTDIR"
rm -f open-vm-tools.p5m.1 open-vm-tools.p5m
rm -rf my-repository
rm -f open-vm-tools.p5p
rm -f open-vm-tools.crt open-vm-tools.key
rm -rf libressl-*
