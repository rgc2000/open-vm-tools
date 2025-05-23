################################################################################
### Copyright (c) 2009-2024 Broadcom. All Rights Reserved.
### Broadcom Confidential. The term "Broadcom" refers to Broadcom Inc.
### and/or its subsidiaries.
###
### This program is free software; you can redistribute it and/or modify
### it under the terms of version 2 of the GNU General Public License as
### published by the Free Software Foundation.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###
### You should have received a copy of the GNU General Public License
### along with this program; if not, write to the Free Software
### Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
################################################################################

bin_PROGRAMS = vmtoolsd

vmtoolsd_CPPFLAGS =
vmtoolsd_CPPFLAGS += @VMTOOLS_CPPFLAGS@
vmtoolsd_CPPFLAGS += @GMODULE_CPPFLAGS@
vmtoolsd_CPPFLAGS += @GOBJECT_CPPFLAGS@
vmtoolsd_CPPFLAGS += @GTHREAD_CPPFLAGS@
vmtoolsd_CPPFLAGS += -I$(builddir)
vmtoolsd_CPPFLAGS += -DVMTOOLSD_PLUGIN_ROOT=\"$(pkglibdir)/plugins\"

vmtoolsd_LDADD =
vmtoolsd_LDADD += @VMTOOLS_LIBS@
vmtoolsd_LDADD += @GMODULE_LIBS@
vmtoolsd_LDADD += @GOBJECT_LIBS@
vmtoolsd_LDADD += @GTHREAD_LIBS@
if LINUX
vmtoolsd_LDADD += ../../lib/globalConfig/libGlobalConfig.la
endif

vmtoolsd_SOURCES =
vmtoolsd_SOURCES += cmdLine.c
vmtoolsd_SOURCES += mainLoop.c
vmtoolsd_SOURCES += mainPosix.c
vmtoolsd_SOURCES += pluginMgr.c
vmtoolsd_SOURCES += serviceObj.c
vmtoolsd_SOURCES += threadPool.c
vmtoolsd_SOURCES += toolsRpc.c
vmtoolsd_SOURCES += svcSignals.c
vmtoolsd_SOURCES += toolsHangDetector.c

BUILT_SOURCES =
BUILT_SOURCES += svcSignals.c
BUILT_SOURCES += svcSignals.h

CLEANFILES =
CLEANFILES += svcSignals.c
CLEANFILES += svcSignals.h

EXTRA_DIST =
EXTRA_DIST += svcSignals.gm

svcSignals.c: $(top_srcdir)/services/vmtoolsd/svcSignals.gm
	glib-genmarshal --body $(top_srcdir)/services/vmtoolsd/svcSignals.gm > \
	   $@ || (rm -f $@ && exit 1)

svcSignals.h: $(top_srcdir)/services/vmtoolsd/svcSignals.gm
	glib-genmarshal --header $(top_srcdir)/services/vmtoolsd/svcSignals.gm > \
	   $@ || (rm -f $@ && exit 1)

if HAVE_ICU
   vmtoolsd_LDADD += @ICU_LIBS@
   vmtoolsd_LINK = $(LIBTOOL) --tag=CXX $(AM_LIBTOOLFLAGS)     \
                      $(LIBTOOLFLAGS) --mode=link $(CXX)       \
                      $(AM_CXXFLAGS) $(CXXFLAGS) $(AM_LDFLAGS) \
                      $(LDFLAGS) -o $@
else
   vmtoolsd_LINK = $(LINK)
endif

# Message catalogs.
install-data-hook:
	@INSTVMSG@ vmtoolsd $(srcdir)/l10n $(DESTDIR)$(datadir)

if SOLARIS
install-exec-hook:
	$(INSTALL) -d $(DESTDIR)/etc/vmware-tools
	$(INSTALL) -d $(DESTDIR)/$(PAM_PREFIX)/pam.d/
	$(INSTALL) $(top_srcdir)/pam/solaris $(DESTDIR)/$(PAM_PREFIX)/pam.d/vmtoolsd
else
if MACOS
install-exec-hook:
	$(INSTALL) -d $(DESTDIR)/etc/vmware-tools
	$(INSTALL) -d $(DESTDIR)/$(PAM_PREFIX)/pam.d/
	$(INSTALL) $(top_srcdir)/pam/macos $(DESTDIR)/$(PAM_PREFIX)/pam.d/vmtoolsd
else
install-exec-hook:
	$(INSTALL) -d $(DESTDIR)/etc/vmware-tools
	$(INSTALL) -d $(DESTDIR)/$(PAM_PREFIX)/pam.d/
	$(INSTALL) $(top_srcdir)/pam/generic $(DESTDIR)/$(PAM_PREFIX)/pam.d/vmtoolsd
endif
endif

uninstall-hook:
	rm -f $(DESTDIR)/$(PAM_PREFIX)/pam.d/vmtoolsd
	rm -rf $(DESTDIR)/etc/vmware-tools

