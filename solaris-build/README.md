Solaris operating instructions
==============================
This document will describe how to install and use the open-vm-tools on Solaris 11.4

You should get the solaris package from the githup page, name should be like open-vm-tools-X.XX.XX.p5p

Status
------
This is the status of the open-vm-tools features supported on Solaris
| Feature | Type | Status | Comments |
|:-------:|:----:|:------:|:--------:|
| vmtoolsd | daemon | working | Main service, will load the plugins |
| vgauthd | daemon | working | Authentication service from host RPC |
| appInfo | plugin | working | needs more tests |
| componentMgr | plugin | unavailable | unknown status |
| containerInfo | plugin | unavailable | unknown status |
| deployPkg | plugin | unavailable | can be compiled if you provide libmspack but host will not allow you to use this feature is GuestOS is set to Solaris |
| desktopEvents | plugin | working | for gfx desktop |
| dndcp | plugin | working | Drag'n drop on desktop for wmware workstation/fusion |
| gdp | plugin | unavailable | unknown status |
| guestInfo | plugin | working | needs more tests |
| guestStore | plugin | unavailable | needs VMCI not available on Solaris |
| hgfsServer | plugin | working | how to test this ? |
| powerOps | plugin | working | confirmed ok |
| resolutionKMS | plugin | unavailable | can be compiled but will not work |
| resolutionSet | plugin | working | change desktop resolutionn on resize |
| serviceDiscovery | plugin | unavailable | not tested |
| timeSync | pkugin | working | tested ok |
| vix | plugin | working | tested ok |
| vmbackup | plugin | working | tested ok called on quiesce on snapshot |
| vmblock | filesystem | working | sharing mecanism for drag'n drop on or from desktop |
| vmhgfs | filesystem | working | file sharing on vmware workstation/fusion |
| vmmemctl | driver | working | memory controller for ballooning |
| vmxnet | driver | working | deprecated network driver |
| vmxnet3s | driver | working | paravirtualized network interface driver, need to be updated to latest kernel API |

Requirements
------------
Minimum Solaris version has to be Solaris 11.4.42 CBE (public available release) or Solaris 11.4.21 SRU (support subscription required)
open-vm-tools cannot run or be compiled on previous versions of Solaris due to required libraries not available or too old.

## Solaris 11.4 installed packages requirements
| Build Dependencies | Runtime |
|:------------------:|:-------:|
| `gnu-make` | `libdnet` |
| `autoconf` | `xmlsec` |
| `automake` |
| `libtool` |
| `pkg-config` | 
| `gcc` |
| `solaris-desktop` |

Installation
------------
Execute this command with root privileges :
```
pkg install -g ./open-vm-tools-X.XX.XX.p5p open-vm-tools
```
Package is installed under standards system directories (/usr/bin /etc /lib).

Configuration is located in /etc/vmware-tools/ directory
Default configuration should be fine for most people but you can create your own /etc/vmware-tools/tools.conf to match your needs.

SMF Services
------------
There will be 4 SMF services defined :

* svc:/open-vm-tools/vmtoolsd:default
This service will be enabled and started. It is the main service that will start the vmtoolsd daemon to
allow OS control from the VMware hypervisor
```
# svcs -xv svc:/open-vm-tools/vmtoolsd:default
svc:/open-vm-tools/vmtoolsd:default (Open VM Tools main agent for VMware)
 State: online since Thu Sep 21 09:41:53 2023
   See: /var/svc/log/open-vm-tools-vmtoolsd:default.log
Impact: None.
```
* svc:/open-vm-tools/balooning:default
This service is not enabled by default. It will load the vmmemctl kernel driver. Its goal is to allow VMware
to reduce memory usage in the virtual machine in situations where the total physical memory is exhausted on
hypervisor. This may have a serious impact on applications running on the VM.

* svc:/open-vm-tools/shares
This service will be automatically enabled on VMware Worksation or VMware Fusion only and it makes no sense
to use it under ESXi. It will load the kernel drivers needed to mount the hgfs share needed to transfer files
between the host and the VM. Default mountpoint is /hgfs but this can be configured with the hgfs_mountpoint 
property of this service.
This service will also allow the copy/paste and drag'n drop feature between host and VM if VM is running the
graphical Solaris desktop.

* svcs:/open-vm-tools/vgauth
This service will be enabled and started. It will be used to provide user authentification for systems with pix
enabled plugin to run commands in the guest from the host gor example.

Drivers
-------
* `vmxnet3s` : VMware EtherAdapter v3
* `vmxnet`   : VMware Ethernet Adapter (deprecated)
* `vmblock`  : VMBlock File system (for copy/paste on VMware workstation)
* `vmmemctl` : VMware Memory Control (ballooning)
* `vmhgfs`   : Host/Guest Filesystem

Network drivers will be loaded only if corresponding virtual hardware is detected.
Other drivers are loaded by the SMF services that need them.

Libraries
---------
The libappmonitor is compiled and instaled by the pkg. It is usefull to create a daemon to provide a heartbeat
for application monitoring in a vSphere HA configuration. Such a service may be released in the future to
detect system hang to make HA service to restart the VM (only useful on VMware clusters with HA enabled)
