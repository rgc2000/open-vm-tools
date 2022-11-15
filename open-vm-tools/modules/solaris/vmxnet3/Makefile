#!/usr/bin/make -f
##########################################################
# Copyright (C) 2009 VMware, Inc. All rights reserved.
#
# The contents of this file are subject to the terms of the Common
# Development and Distribution License (the "License") version 1.0
# and no later version.  You may not use this file except in
# compliance with the License.
#
# You can obtain a copy of the License at
#         http://www.opensource.org/licenses/cddl1.php
#
# See the License for the specific language governing permissions
# and limitations under the License.
#
##########################################################

ifneq ($(shell echo "$(VM_UNAME)" | cut -c-4),5.10)
SUPPORTED := 1
endif

ifneq ($(shell echo "$(VM_UNAME)" | cut -c-4),5.11)
SUPPORTED := 1
endif

$(if $(SUPPORTED),,$(error "Unsupported Solaris version: $(VM_UNAME)"))

##
## General build locations and variables
##

MODULE    := vmxnet3s
CFLAGS    :=
LDFLAGS   := -dy -Nmisc/mac

CFLAGS    += -O2
CFLAGS    += -Wall -Werror -Wno-unknown-pragmas
CFLAGS    += -U_NO_LONGLONG
CFLAGS    += -D_KERNEL
CFLAGS    += -I../../../lib/include    # for buildNumber.h

CFLAGS    += -ffreestanding
CFLAGS    += -nodefaultlibs

ifdef OVT_SOURCE_DIR
   CFLAGS += -I$(OVT_SOURCE_DIR)/lib/include
   CFLAGS += -I$(OVT_SOURCE_DIR)/modules/shared/vmxnet
endif


ifeq ($(shell echo "$(VM_UNAME)" | cut -c-4),5.10)
CFLAGS  += -DSOL10
endif

ifeq ($(shell echo "$(VM_UNAME)" | cut -c-4),5.11)
CFLAGS  += -DSOL11
endif

CFLAGS_32  := $(CFLAGS)
CFLAGS_32  += -m32
LDFLAGS_32 := $(LDFLAGS)

CFLAGS_64  := $(CFLAGS)
CFLAGS_64  += -m64
CFLAGS_64  += -mcmodel=kernel
CFLAGS_64  += -mno-red-zone
LDFLAGS_64 := $(LDFLAGS)
ifdef HAVE_GNU_LD
LDFLAGS_64 += -m elf_x86_64
else
LDFLAGS_64 += -64
endif

##
## Objects needed to build the HGFS kernel module
##
VMXNET3_OBJS := vmxnet3_main.o
VMXNET3_OBJS += vmxnet3_utils.o
VMXNET3_OBJS += vmxnet3_tx.o
VMXNET3_OBJS += vmxnet3_rx.o

VMXNET3_32_OBJS := $(addprefix i386/, $(VMXNET3_OBJS))
VMXNET3_64_OBJS := $(addprefix amd64/, $(VMXNET3_OBJS))

MODULE_32 := i386/$(MODULE)
MODULE_64 := amd64/$(MODULE)

ifeq ($(shell echo "$(VM_UNAME)" | cut -c-4),5.10)
MODULES := $(MODULE_32) $(MODULE_64)
INSTALL := install32 install64
endif

ifeq ($(shell echo "$(VM_UNAME)" | cut -c-4),5.11)
MODULES := $(MODULE_64)
INSTALL := install64
endif

all: prepare_dirs $(MODULES)

prepare_dirs:
	@echo "Creating build directories"
	mkdir -p i386
	mkdir -p amd64

$(MODULE_32): $(VMXNET3_32_OBJS)
	@echo "Linking          $@"
	$(LD) $(LDFLAGS_32) -r $(VMXNET3_32_OBJS) -o $@

$(VMXNET3_32_OBJS): i386/%.o: %.c
	@echo "Compiling        $(<F)"
	$(CC) $(CFLAGS_32) -c $< -o $@

$(MODULE_64): $(VMXNET3_64_OBJS)
	@echo "Linking          $@"
	$(LD) $(LDFLAGS_64) -r $(VMXNET3_64_OBJS) -o $@

$(VMXNET3_64_OBJS): amd64/%.o: %.c
	@echo "Compiling        $(<F)"
	$(CC) $(CFLAGS_64) -c $< -o $@

clean:
	@echo "Cleaning directories"
	@rm -rf $(MODULE_32) $(VMXNET3_32_OBJS) i386
	@rm -rf $(MODULE_64) $(VMXNET3_64_OBJS) amd64

install32:
	@echo "Installing modules 32"
	[ -d $(DESTDIR)/kernel/drv ] || mkdir -p $(DESTDIR)/kernel/drv
	cp $(MODULE_32) $(DESTDIR)/kernel/drv/
	chmod 755 $(DESTDIR)/kernel/drv/$(MODULE)

install64:
	@echo "Installing modules 64"
	[ -d $(DESTDIR)/kernel/drv/amd64 ] || mkdir -p $(DESTDIR)/kernel/drv/amd64
	cp $(MODULE_64) $(DESTDIR)/kernel/drv/amd64
	chmod 755 $(DESTDIR)/kernel/drv/amd64/$(MODULE)

install: $(INSTALL)
	@echo "Installing modules configuration"
	[ -d $(DESTDIR)/kernel/drv ] || mkdir -p $(DESTDIR)/kernel/drv
	cp vmxnet3s.conf $(DESTDIR)/kernel/drv/vmxnet3s.conf
	chmod 644 $(DESTDIR)/kernel/drv/vmxnet3s.conf
