Solaris operating instructions
------------------------------
This document will describe how to install and use the vmware-tools on Solaris 11

You should get the solaris package from the githup page, name should be like open-vm-tools-X.XX.XX.p5p

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

SMF Service
-----------
An SMF service is defined, enabled and started. Its name is svc:/vmware/vmware-tools:default
```
# svcs -xv svc:/vmware/vmware-tools:default
svc:/vmware/vmware-tools:default (Open VM Tools for VMWare)
 State: online since Tue Nov 15 15:04:17 2022
   See: /var/svc/log/vmware-vmware-tools:default.log
Impact: None.
```

Drivers
-------
* `vmxnet3s` : VMware EtherAdapter v3
* `vmxnet`   : VMware Ethernet Adapter (deprecated)
* `vmblock`  : VMBlock File system (for copy/paste on VMware workstation)
* `vmmemctl` : VMware Memory Control (ballooning)
* `vmhgfs`   : Host/Guest Filesystem

Only network drivers will be loaded if corresponding virtual hardware is detected.
Other drivers need to be loaded manually using modload
