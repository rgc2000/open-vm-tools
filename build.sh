#!/usr/bin/ksh
# Build script to create Solatis 11 pkg files for open-vm-tools

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
            11.3)
                OPTION="-DSOL113"
                ;;
            11.4|11.5)
                OPTION="-DSOL114"
                ;;
            *)
                OPTION=""
                ;;
        esac

        # =======  Compile libdnet

        cd libdnet-1.11
        ./configure --prefix=/opt/vmware --disable-static
        /usr/gnu/bin/sed -i 's/eth-linux\$U/eth-none$U/g' src/Makefile
        gmake -j 5
        gmake install
        ln -fs libdnet $DESTDIR/opt/vmware/lib/libdnet.so
        cd ..

        # =======  Compile open-vm-tools

        export "PATH=$DESTDIR/opt/vmware/bin:$PATH"

        cd open-vm-tools
        autoreconf -i
        ./configure --prefix=/opt/vmware --disable-static --without-x --enable-libappmonitor CFLAGS="-I$DESTDIR/opt/vmware/include -L$DESTDIR/opt/vmware/lib $OPTION -Wno-unused-variable"
        gmake -j 5
        gmake install
        cd ..

        # =======  Clean files

        find $DESTDIR -type f -exec file {} \; | grep 'not stripped' | cut -d: -f1 | xargs -t -L 1 strip
        mv $DESTDIR/sbin $DESTDIR/usr/sbin
        mkdir -p $DESTDIR/usr/lib/fs/vmblock
        mkdir -p $DESTDIR/usr/lib/fs/vmhgfs
        mkdir -p $DESTDIR/etc/fs
        ln -fs /opt/vmware/sbin/mount.vmblock $DESTDIR/usr/lib/fs/vmblock/mount
        ln -fs /opt/vmware/sbin/mount.vmhgfs $DESTDIR/usr/lib/fs/vmhgfs/mount
        ln -fs /usr/lib/fs/vmblock $DESTDIR/etc/fs/vmblock
        ln -fs /usr/lib/fs/vmhgfs $DESTDIR/etc/fs/vmhgfs
        ln -fs /opt/vmware/bin/vmtoolsd $DESTDIR/usr/sbin/vmtoolsd
        ln -fs /opt/vmware/bin/vmware-toolbox-cmd $DESTDIR/usr/bin/vmware-toolbox-cmd
        rm -f $DESTDIR/usr/sbin/mount.*

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

        pkgsend generate $DESTDIR | pkgfmt |
            grep -v 'dir  path=etc ' |
            grep -v 'dir  path=etc/fs ' |
            grep -v 'dir  path=etc/pam.d ' |
            grep -v 'dir  path=etc/certs' |
            grep -v 'dir  path=kernel ' |
            grep -v 'dir  path=kernel/drv ' |
            grep -v 'dir  path=kernel/drv/amd64 ' |
            grep -v 'dir  path=opt ' |
            grep -v 'dir  path=usr ' |
            grep -v 'dir  path=usr/lib ' |
            grep -v 'dir  path=usr/lib/fs ' |
            grep -v 'dir  path=usr/sbin ' |
            grep -v 'dir  path=usr/bin ' > open-vm-tools.p5m.1

        cp -pr proto/lib "$DESTDIR"

        cat open-vm-tools-header.p5m open-vm-tools.p5m.1 open-vm-tools-footer.p5m > open-vm-tools.p5m

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

