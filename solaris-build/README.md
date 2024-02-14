Solaris operating instructions
==============================
This document will describe how to compile, install and use the open-vm-tools on Solaris 11.4

You should get the solaris binary package from the githup page, name should be like open-vm-tools-X.X.X-Y.p5p where X.X.X is the open-vm-tools source version as released by the vmware team and Y is the package revision as released by this git project branch.

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
| deployPkg | plugin | unavailable | can be compiled if you provide libmspack but host will not allow you to use this feature when GuestOS is set to Solaris |
| desktopEvents | plugin | working | for gfx desktop |
| dndcp | plugin | working | Drag'n drop on desktop for wmware workstation/fusion |
| gdp | plugin | unavailable | unknown status |
| guestInfo | plugin | working | needs more tests |
| guestStore | plugin | unavailable | needs VMCI not available on Solaris |
| hgfsServer | plugin | working | how to test this ? |
| powerOps | plugin | working | confirmed ok |
| resolutionKMS | plugin | unavailable | can be compiled but will not work |
| resolutionSet | plugin | working | change desktop resolutionn on display resize |
| serviceDiscovery | plugin | unavailable | not tested |
| timeSync | pkugin | working | tested ok |
| vix | plugin | working | tested ok |
| vmbackup | plugin | working | tested ok called for quiesce on snapshot |
| vmblock | filesystem | working | sharing mecanism for drag'n drop on or from desktop |
| vmhgfs | filesystem | working | file sharing on vmware workstation/fusion |
| vmmemctl | driver | working | memory controller for ballooning |
| vmxnet | driver | working | deprecated network driver |
| vmxnet3s | driver | working | paravirtualized network interface driver, needs to be updated to latest kernel API |

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

Build
-----
* Required packages installation for compilation
Execute the following command to install the needed packages for compilation (not needed for runtime except libdnet and xmlsec). Packages will be pulled from IPS repository, so be sure to have configured the IPS publishers according to your Solaris version.
```
pkg install gnu-make autoconf automake libtool pkg-config gcc libdnet xmlsec solaris-desktop
```

* Compilation
If you prefer to compile and build your own package execute this command with a non privileged account :
```
cd solaris-build
./build.sh
```
Generated package file name will be open-vm-tools.p5p
* Clean
To remove all the generated files execute command
```
cd solaris-build
./clean.sh
```
 
Installation
------------
Execute this command with root privileges, required packages will be pulled from IPS publisher if needed (libdnet and xmlsec):
```
pkg install -g open-vm-tools-X.X.X-Y.p5p open-vm-tools
```
Package is installed under standards system directories (/usr/bin /etc /lib).

Configuration is located in /etc/vmware-tools/ directory
Default configuration should be fine for most people but you can create your own /etc/vmware-tools/tools.conf to match your needs.

SMF Services
------------
There will be 4 SMF services defined :

* svc:/open-vm-tools/vmtoolsd:default
This service will be enabled and started by default. It is the main service that will start the vmtoolsd daemon to
allow OS monitoring and control from the VMware hypervisor
```
# svcs -xv svc:/open-vm-tools/vmtoolsd:default
svc:/open-vm-tools/vmtoolsd:default (Open VM Tools main agent for VMware)
 State: online since Thu Sep 21 09:41:53 2023
   See: /var/svc/log/open-vm-tools-vmtoolsd:default.log
Impact: None.
```
* svc:/open-vm-tools/balloon:default
This service is not enabled by default. It will load the vmmemctl kernel driver. Its goal is to allow VMware
to reduce memory usage in the virtual machine in situations where the total physical memory is exhausted on
hypervisor. This may have a serious impact on application performances running on the VM.

* svc:/open-vm-tools/shares:default
This service will be automatically enabled on VMware Worksation or VMware Fusion only and it makes no sense
to use it under ESXi. It will load the kernel drivers needed to mount the hgfs share needed to transfer files
between the host and the VM. Default mountpoint is /hgfs but this can be configured with the hgfs_mountpoint 
property of this service.
This service will also allow the copy/paste and drag'n drop feature between host and VM if VM is running the
graphical Solaris desktop.

* svc:/open-vm-tools/vgauth:default
This service will be enabled and started by default. It will be used to provide user authentification for systems with pix
enabled plugin to run commands in the guest from the host for example.

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
