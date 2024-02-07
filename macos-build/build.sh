#!/bin/bash
# Build script to create MacOS pkg file for open-vm-tools

umask 022

export PREFIX=/usr/local
export SYSCONFDIR=/etc
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
        ./configure --enable-silent-rules --prefix=${PREFIX} --sysconfdir=${SYSCONFDIR} --libdir=${LIBDIR} --disable-static --enable-libappmonitor --without-x --disable-resolutionkms --enable-vmwgfxctrl --enable-vgauth
        make -j 5
        make install
        cd ../macos-build

        # =======  Clean files

        find ${DESTDIR} -type f -exec file {} \; | grep 'not stripped' | cut -d: -f1 | xargs -t -L 1 strip

        if [ "${SYSCONFDIR}" != "/etc" ]
        then
            [ -d "${DESTDIR}/etc/fs" ] || mkdir -p "${DESTDIR}/etc/fs"
            [ -d "${DESTDIR}/etc/xdg/autostart" ] || mkdir -p "${DESTDIR}/etc/xdg/autostart"
            ln -fs $(realpath --relative-to=/etc/xdg/autostart "${SYSCONFDIR}/xdg/autostart/vmware-user.desktop") "${DESTDIR}/etc/xdg/autostart/vmware-user.desktop"
            ln -fs $(realpath --relative-to=/etc/fs "${LIBDIR}/fs/vmblock") "${DESTDIR}/etc/fs/vmblock"
            ln -fs $(realpath --relative-to=/etc/fs "${LIBDIR}/fs/vmhgfs") "${DESTDIR}/etc/fs/vmhgfs"
        fi

        [ -f "${DESTDIR}/etc/pam.d/vmtoolsd" ] && chmod -x "${DESTDIR}/etc/pam.d/vmtoolsd"
        [ -f "${DESTDIR}${PREFIX}/bin/vmware-user-suid-wrapper" ] && chmod u+s "${DESTDIR}${PREFIX}/bin/vmware-user-suid-wrapper"
        chmod -x ${DESTDIR}${LIBDIR}/lib*

        echo "Compilation for MacOS finished"
        ;;

    *)
        echo "Don't know how to compile for ${TARGETOS}, aborting"
esac

