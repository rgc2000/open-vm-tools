#!/bin/bash
# Build script to create MacOS pkg file for open-vm-tools

umask 022

export PREFIX="/usr/local"
export SYSCONFDIR="/etc"
export LIBDIR=${PREFIX}/lib
export DESTDIR=/tmp/vmtools-build
export LD_RUN_PATH=${LIBDIR}

TARGETOS=$(uname -s)

case "${TARGETOS}" in
    Darwin)
        export MAKE="make"

        # =======  Compile open-vm-tools

        cd ../open-vm-tools
        autoreconf -i
        ./configure --enable-silent-rules --prefix="${PREFIX}" --sysconfdir="${SYSCONFDIR}" --libdir="${LIBDIR}" --disable-static --enable-libappmonitor --without-x --enable-resolutionkms --enable-vgauth
        make -j 5
        make install
        cd ../macos-build

        # =======  Clean files

        find ${DESTDIR} -type f -exec file {} \; | grep 'Mach-O' | cut -d: -f1 | xargs -t -L 1 strip -x -S

        [ -f "${DESTDIR}/etc/pam.d/vmtoolsd" ] && chmod -x "${DESTDIR}/etc/pam.d/vmtoolsd"
        [ -f "${DESTDIR}${PREFIX}/bin/vmware-user-suid-wrapper" ] && chmod u+s "${DESTDIR}${PREFIX}/bin/vmware-user-suid-wrapper"
        chmod -x ${DESTDIR}${LIBDIR}/lib*

        echo "Compilation for MacOS finished"
        ;;

    *)
        echo "Don't know how to compile for ${TARGETOS}, aborting"
esac

