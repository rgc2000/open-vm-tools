#                      open-vm-tools 13.0.10 Release Notes

Updated on: 20 Jan 2026

open-vm-tools | 20 JAN 2026 | Build 25056151

Check back for additions and updates to these release notes.

## What's in the Release Notes

The release notes cover the following topics:

* [What's New](#whatsnew) 
* [Internationalization](#i18n) 
* [Guest Operating System Customization Support](#guestop) 
* [Interoperability Matrix](#interop) 
* [Resolved Issues](#resolvedissues) 
* [Known Issues](#knownissues)

## <a id="whatsnew" name="whatsnew"></a>What's New

*   Please see the [Resolved Issues](#resolvedissues) and [Known Issues](#knownissues) sections below.

*   A complete list of the granular changes in the open-vm-tools 13.0.10 release is available at:

    [open-vm-tools ChangeLog](https://github.com/vmware/open-vm-tools/blob/stable-13.0.10/open-vm-tools/ChangeLog)

## <a id="i18n" name="i18n"></a>Internationalization

open-vm-tools 13.0.10 is available in the following languages:

* English
* French
* Japanese
* Spanish

## <a id="guestop" name="guestop"></a>Guest Operating System Customization Support

The [Broadcom Guest OS Compatibility Guide (filtered for Guest Customization)](https://compatibilityguide.broadcom.com/search?program=software&persona=live&customization=Guest+Customization&column=osVendors&order=asc) provides details about the guest operating systems supported for customization.


## <a id="interop" name="interop"></a>Interoperability Matrix

The [Broadcom Product Interoperability Matrix](https://interopmatrix.broadcom.com/Interoperability) provides details about the compatibility of current and earlier versions of VMware Products. 

## <a id="resolvedissues" name ="resolvedissues"></a> Resolved Issues

*   **During Linux guest customization, open-vm-tools may reboot the VM without waiting for cloud-init execution to complete if cloud-init encounters a recoverable error**

    [Issue #768](https://github.com/vmware/open-vm-tools/issues/768) Make GetCloudinitStatus() more robust 

    Starting with cloud-init version 23.4, an error code was introduced to signal a recoverable error. open-vm-tools interprets this error code as a cloud-init execution failure, so continues executing guest customization with a VM reboot in the end. 

    This issue is resolved in this release. During Linux guest customization, open-vm-tools now correctly waits for cloud-init execution to complete, even when cloud-init encounters recoverable errors.

## <a id="knownissues" name="knownissues"></a>Known Issues

*   **Shared Folders mount is unavailable on Linux VM.**

    If the **Shared Folders** feature is enabled on a Linux VM while it is powered off, the shared folders mount is not available on restart.

    Note: This issue is applicable to open-vm-tools running on VMware Workstation and VMware Fusion.

    Workaround:

    If the VM is powered on, disable and enable the **Shared Folders** feature from the interface. For resolving the issue permanently, edit **/etc/fstab** and add an entry to mount the Shared Folders automatically on boot.  For example, add the line:

    <tt>vmhgfs-fuse   /mnt/hgfs    fuse    defaults,allow_other    0    0</tt>

    For more information on how to configure open-vm-tools Shared Folders, see [KB 60262](https://knowledge.broadcom.com/external/article?legacyId=60262).
