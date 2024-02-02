#!/bin/bash
# Script to clean MacOS pkg files build

export DESTDIR=/tmp/vmtools-build

# =======  Clean open-vm-tools

cd ../open-vm-tools
make distclean
cd ../solaris-build

# =======  Clean files

rm -rf "$DESTDIR"
