#!/usr/bin/ksh
# Build script to create Solatis 11 pkg file for open-vm-tools

umask 022

export DESTDIR=/tmp/vmtools-build
export LD_RUN_PATH=/opt/vmware/lib
export PKG_CONFIG_PATH=/usr/lib/64/pkgconfig

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
	./configure --prefix=/opt/vmware --disable-static --enable-libappmonitor CFLAGS="-Wno-unused-variable"
        gmake -j 5
        gmake install
        cd ../solaris-build

        # =======  Clean files

        find $DESTDIR -type f -exec file {} \; | grep 'not stripped' | cut -d: -f1 | xargs -t -L 1 strip
        mv $DESTDIR/sbin $DESTDIR/usr/sbin
        mkdir -p $DESTDIR/usr/lib/fs/vmblock
        mkdir -p $DESTDIR/usr/lib/fs/vmhgfs
        mkdir -p $DESTDIR/etc/fs
        mkdir -p $DESTDIR/etc/xdg/autostart
        ln -fs /opt/vmware/sbin/mount.vmblock $DESTDIR/usr/lib/fs/vmblock/mount
        ln -fs /opt/vmware/sbin/mount.vmhgfs $DESTDIR/usr/lib/fs/vmhgfs/mount
        ln -fs /usr/lib/fs/vmblock $DESTDIR/etc/fs/vmblock
        ln -fs /usr/lib/fs/vmhgfs $DESTDIR/etc/fs/vmhgfs
        ln -fs /opt/vmware/bin/vmtoolsd $DESTDIR/usr/sbin/vmtoolsd
        ln -fs /opt/vmware/bin/vmware-toolbox-cmd $DESTDIR/usr/bin/vmware-toolbox-cmd
        ln -fs /opt/vmware/etc/xdg/autostart/vmware-user.desktop $DESTDIR/etc/xdg/autostart/vmware-user.desktop
        rm -f $DESTDIR/usr/sbin/mount.*
        [ -f $DESTDIR/etc/pam.d/vmtoolsd ] && chmod -x $DESTDIR/etc/pam.d/vmtoolsd
        [ -f $DESTDIR/opt/vmware/bin/vmware-user-suid-wrapper ] && chmod u+s $DESTDIR/opt/vmware/bin/vmware-user-suid-wrapper
        chmod -x $DESTDIR/opt/vmware/lib/lib*

        # =======  Sign solaris drivers

        ./new-cert.sh

        for i in $DESTDIR/kernel/drv/amd64/*
        do
            echo "signing $i"
            elfsign sign -F rsa_sha256 -c open-vm-tools.crt -k open-vm-tools.key -e $i
            chmod -wx "$i"
        done

        mkdir -p "$DESTDIR/etc/certs/elfsign"
        cp -p open-vm-tools.crt "$DESTDIR/etc/certs/elfsign"

        # =======  Create pkg files manifest

        cp -pr proto/etc "$DESTDIR"

        pkgsend generate $DESTDIR | pkgfmt > open-vm-tools.p5m.1

        cp -pr proto/lib "$DESTDIR"

        cat open-vm-tools-header.p5m open-vm-tools.p5m.1 open-vm-tools-footer.p5m > open-vm-tools.p5m

        for dir in etc etc/certs etc/certs/elfsign etc/fs etc/pam.d etc/xdg etc/xdg/autostart kernel kernel/drv kernel/drv/amd64 opt usr usr/lib/fs
        do
            sed "s,path=$dir owner=root group=bin,path=$dir owner=root group=sys," open-vm-tools.p5m > open-vm-tools.p5m.a &&
	    mv open-vm-tools.p5m.a open-vm-tools.p5m
        done

        rm -rf my-repository
        mkdir my-repository
        pkgrepo create my-repository
        pkgrepo -s my-repository add-publisher community
        pkgsend publish -d "$DESTDIR" -s ./my-repository open-vm-tools.p5m
        pkgrecv -s my-repository -a -d open-vm-tools.p5p vmware/open-vm-tools

        echo "Compilation for Solaris finished, pkg is open-vm-tools.p5p"
        ;;

    *)
        echo "Don't know hox to compile for ${TARGETOS}, aborting"
esac

