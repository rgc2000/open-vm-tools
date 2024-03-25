/*********************************************************
 * Copyright (C) 1998-2019, 2021-2023 VMware, Inc. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation version 2.1 and no later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser GNU General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA.
 *
 *********************************************************/

/*
 * utilMacOS.h --
 *
 *    misc MacOS util functions
 */

#ifndef __UTIL_MACOS_H__
#define __UTIL_MACOS_H__

#if defined(__APPLE__)
#include <sys/stat.h>
#include <CoreFoundation/CoreFoundation.h>
#endif

#include "vmware.h"
#include "msg.h"
#include "util.h"
#include "str.h"
#include "su.h"
#include "escape.h"
#include "posix.h"
#include "unicode.h"

/*
 * ESX with userworld VMX
 */
#if defined(VMX86_SERVER)
#include "hostType.h"
#include "user_layout.h"
#endif

#if defined(__APPLE__)

char * Util_CFStringToUTF8CString(CFStringRef s);

CFDictionaryRef UtilMacos_CreateCFDictionaryWithContentsOfFile(const char *path);

Bool UtilMacos_ReadSystemVersion(CFDictionaryRef versionDict,
                                 char **productName,
                                 char **productVersion,
                                 char **productBuildVersion);

#endif // defined(__APPLE__)

#endif   /* __UTIL_MACOS_H__ */
