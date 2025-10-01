#                      open-vm-tools 13.0.5 Release Notes

Updated on: 29 Sep 2025

open-vm-tools | 29 SEP 2025 | Build 24915695

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

*   This release resolves [CVE-2025-41244](https://www.cve.org/CVERecord?id=CVE-2025-41244). For more information on this vulnerability and its impact on Broadcom products, see [VMSA-2025-0015](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/36149).

    A patch to address CVE-2025-41244 on earlier open-vm-tools releases is provided to the Linux community at [CVE-2025-41244.patch](https://github.com/vmware/open-vm-tools/tree/CVE-2025-41244.patch).

*   Guest OS Customization has been updated to use "systemctl reboot", if available.

*   Please see the [Resolved Issues](#resolvedissues) and [Known Issues](#knownissues) sections below.

*   A complete list of the granular changes in the open-vm-tools 13.0.5 release is available at:

    [open-vm-tools ChangeLog](https://github.com/vmware/open-vm-tools/blob/stable-13.0.5/open-vm-tools/ChangeLog)

## <a id="i18n" name="i18n"></a>Internationalization

open-vm-tools 13.0.5 is available in the following languages:

* English
* French
* Japanese
* Spanish

## <a id="guestop" name="guestop"></a>Guest Operating System Customization Support

The [Guest OS Customization Support Matrix](https://compatibilityguide.broadcom.com/search?program=software&persona=live&customization=Guest+Customization&column=osVendors&order=asc) provides details about the guest operating systems supported for customization.


## <a id="interop" name="interop"></a>Interoperability Matrix

The [Broadcom Product Interoperability Matrix](https://interopmatrix.broadcom.com/Interoperability) provides details about the compatibility of current and earlier versions of VMware Products. 

## <a id="resolvedissues" name ="resolvedissues"></a> Resolved Issues

*   **This release resolves CVE-2025-41244.**

    * For more information on this vulnerability and its impact on Broadcom products, see [VMSA-2025-0015](https://support.broadcom.com/web/ecx/support-content-notification/-/external/content/SecurityAdvisories/0/36149).

    * A patch to address CVE-2025-41244 on earlier open-vm-tools releases is provided to the Linux community at [CVE-2025-41244.patch](https://github.com/vmware/open-vm-tools/tree/CVE-2025-41244.patch).

*   **Guest OS Customization updated to use "systemctl reboot".**

    Currently the "telinit 6" command is used to reboot a Linux VM following Guest OS Customization.  As the classic Linux init system, SysVinit, is deprecated in favor of a newer init system, systemd, the telinit command may not be available on the base Linux OS.

    This change adds support to Guest OS Customization for the systemd init system.  If the modern init system, systemd, is available, then a "systemctl reboot" command will be used to trigger reboot.  Otherwise, the "telinit 6" command will be used assuming the traditional init system, SysVinit, is still available.


## <a id="knownissues" name="knownissues"></a>Known Issues

*   **Shared Folders mount is unavailable on Linux VM.**

    If the **Shared Folders** feature is enabled on a Linux VM while it is powered off, the shared folders mount is not available on restart.

    Note: This issue is applicable to open-vm-tools running on VMware Workstation and VMware Fusion.

    Workaround:

    If the VM is powered on, disable and enable the **Shared Folders** feature from the interface. For resolving the issue permanently, edit **/etc/fstab** and add an entry to mount the Shared Folders automatically on boot.  For example, add the line:

    <tt>vmhgfs-fuse   /mnt/hgfs    fuse    defaults,allow_other    0    0</tt>

    For more information on how to configure VMware Tools Shared Folders, see [KB 60262](https://knowledge.broadcom.com/external/article?legacyId=60262).
