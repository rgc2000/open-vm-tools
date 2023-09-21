#!/usr/bin/ksh
# Build script to create Solatis 11 pkg file for open-vm-tools

umask 022

export PREFIX=/usr
export SYSCONFDIR=/etc
export LIBDIR=${PREFIX}/lib
export DESTDIR=/tmp/vmtools-build
export LD_RUN_PATH=${LIBDIR}
export PKG_CONFIG_PATH=/usr/lib/amd64/pkgconfig

TARGETOS=$(uname -s)

case "${TARGETOS}" in
    SunOS)
        SOLARIS_VERSION="$(uname -v | cut -d. -f-2)"
        export MAKE="gmake"

        case "${SOLARIS_VERSION}" in
            11.4|11.5)
                ;;
            *)
                echo "Solaris ${SOLARIS_VERSION} not supported, aborting"
                exit 1
                ;;
        esac

        # =======  Compile open-vm-tools

        cd ../open-vm-tools
        autoreconf -i
        ./configure --enable-silent-rules --prefix=${PREFIX} --sysconfdir=${SYSCONFDIR} --libdir=${LIBDIR} --disable-static --enable-libappmonitor --enable-vgauth
        gmake -j 5
        gmake install
        cd ../solaris-build

        # =======  Clean files

        find ${DESTDIR} -type f -exec file {} \; | grep 'not stripped' | cut -d: -f1 | xargs -t -L 1 strip

        if [ "${PREFIX}" != "/usr" ]
        then
            [ -d "${DESTDIR}/usr/bin" ] || mkdir -p "${DESTDIR}/usr/bin"
            ln -fs $(realpath --relative-to=/usr/bin "${PREFIX}/bin/vmtoolsd") "${DESTDIR}/usr/bin/vmtoolsd"
            ln -fs $(realpath --relative-to=/usr/bin "${PREFIX}/bin/vmware-toolbox-cmd") "${DESTDIR}/usr/bin/vmware-toolbox-cmd"
        fi

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

        # =======  Sign solaris drivers

        ./new-cert.sh

        for i in ${DESTDIR}/kernel/drv/amd64/*
        do
            echo "signing $i"
            elfsign sign -F rsa_sha256 -c open-vm-tools.crt -k open-vm-tools.key -e $i
            chmod -wx "$i"
        done

        mkdir -p "${DESTDIR}/etc/certs/elfsign"
        cp -p open-vm-tools.crt "${DESTDIR}/etc/certs/elfsign"

        # =======  Create pkg files manifest

        pkgsend generate ${DESTDIR} | pkgfmt > open-vm-tools.p5m.1

        cp -pr proto/lib "${DESTDIR}"

        cat open-vm-tools-header.p5m open-vm-tools.p5m.1 open-vm-tools-footer.p5m > open-vm-tools.p5m

        for dir in etc etc/certs etc/certs/elfsign etc/fs etc/pam.d etc/xdg etc/xdg/autostart kernel kernel/drv kernel/drv/amd64 opt usr usr/share usr/lib/fs
        do
            sed "s,path=$dir owner=root group=bin,path=$dir owner=root group=sys," open-vm-tools.p5m > open-vm-tools.p5m.a &&
	    mv open-vm-tools.p5m.a open-vm-tools.p5m
        done

        for dir in usr/lib/pkgconfig
        do
            sed "s,path=$dir owner=root group=bin,path=$dir owner=root group=other," open-vm-tools.p5m > open-vm-tools.p5m.a &&
            mv open-vm-tools.p5m.a open-vm-tools.p5m
        done

        rm -rf my-repository open-vm-tools.p5p
        mkdir my-repository
        pkgrepo create my-repository
        pkgrepo -s my-repository add-publisher community
        pkgsend publish -d "${DESTDIR}" -s ./my-repository open-vm-tools.p5m
        pkgsend publish -d "${DESTDIR}" -s ./my-repository renamed-ovt.p5m
        pkgrecv -s my-repository -a -d open-vm-tools.p5p pkg://community/vmware/open-vm-tools pkg://community/open-vm-tools
        echo "Compilation for Solaris finished, pkg is open-vm-tools.p5p"
        ;;

    *)
        echo "Don't know hox to compile for ${TARGETOS}, aborting"
esac

