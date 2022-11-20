Solaris operating instructions
==============================
This document will describe how to install and use the vmware-tools on Solaris 11

You should get the solaris package from the githup page, name should be like open-vm-tools-X.XX.XX.p5p

Requirements
------------
Minimum Solaris version has to be Solaris 11.3 SRU 20 (Oracle Solaris 11.3.20.5.0).
open-vm-tools cannot run or be compiled on previous versions of Solaris due to too old glib2 library

Installation
------------
Execute this command with root privileges :
```
pkg install -g ./open-vm-tools-X.XX.XX.p5p vmware/open-vm-tools
```
Package is installed under /opt/vmware
Some symbolic links are added in /usr/bin and /usr/sbin to call commands vmware-toolbox-cmd and vmtoolsd

Configuration is located in /etc/vmware-tools/ directory
Default configuration should be fine for most people but you can edit it to match your needs.

SMF Services
------------
There will be 3 SMF services defined :

* svc:/vmware/tools:default
This service will be enabled and started. It is the main service that will start the vmtoolsd daemon to
allow OS control from the VMware hypervisor
```
# svcs -xv svc:/vmware/tools:default
svc:/vmware/tools:default (Open VM Tools for VMware)
 State: online since Tue Nov 15 15:04:17 2022
   See: /var/svc/log/vmware-tools:default.log
Impact: None.
```
* svc:/vmware/balooning:default
This service is not enabled by default. It will load the vmmemctl kernel driver. Its goal is to allow VMware
to reduce memory usage in the virtual machine in situations where the total physical memory is exhausted on
hypervisor. This may have a serious impact on applications running on the VM.

* svc:/vmware/shares
This service will be automatically enabled on VMware Worksation or VMware Fusion only and it makes no sense
to use it under ESXi. It will load the kernel drivers needed to mount the hgfs share needed to transfer files
between the host and the VM. Default mountpoint is /hgfs but this can be configured with the hgfs_mountpoint 
property of this service.
This service will also allow the copy/paste and drag'n drop feature between host and VM if VM is running the
graphical Solaris desktop. This feature is only working under Solaris 11.4. Solaris 11.3 does not allow
copy/paste and DnD.

Drivers
-------
* `vmxnet3s` : VMware EtherAdapter v3
* `vmxnet`   : VMware Ethernet Adapter (deprecated)
* `vmblock`  : VMBlock File system (for copy/paste on VMware workstation)
* `vmmemctl` : VMware Memory Control (ballooning)
* `vmhgfs`   : Host/Guest Filesystem

Only network drivers will be loaded if corresponding virtual hardware is detected.
Other drivers are loaded by the SMF services that need them.

Libraries
---------
This is ugly but the packages includes the libdnet library needed by the vmware-tools. It is available under
Solaris 11.4 but not under 11.3 that's why I have decided to embed it. Maybe if we drop support for Solaris
11.3 it will not be provided anymore.

The libappmonitor is compiled and instaled by the pkg. It is usefull to create a daemon to provide a heartbeat
for application monitoring in a vSphere HA configuration. Such a service may be released in the future to
detect system hang to make HA service to restart the VM (only useful on VMware clusters with HA enabled)
