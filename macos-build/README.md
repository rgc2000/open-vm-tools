MacOS operating instructions
============================
This document will describe how to install and use the open-vm-tools on MacOS 10.14+

You should get the macos package from the githup page, name should be like open-vm-tools-X.XX.XX.pkg

Status
------
This is the status of the open-vm-tools features supported on Solaris
| Feature | Type | Status | Comments |
|:-------:|:----:|:------:|:--------:|
| vmtoolsd | daemon | unknown | Main service, will load the plugins |
| vgauthd | daemon | unknown | Authentication service from host RPC |
| appInfo | plugin | unknown | not tested |
| componentMgr | plugin | unknown | unknown status |
| containerInfo | plugin | unknown | unknown status |
| deployPkg | plugin | unknown | unknown status |
| desktopEvents | plugin | unknown | for gfx desktop |
| dndcp | plugin | unknown | Drag'n drop on desktop for wmware workstation/fusion |
| gdp | plugin | unknown | unknown status |
| guestInfo | plugin | unknown | not tested |
| guestStore | plugin | unknown | not tested |
| hgfsServer | plugin | unknown | not tested |
| powerOps | plugin | unknown | not tested |
| resolutionKMS | plugin | unknown | not tested |
| resolutionSet | plugin | unknown | change desktop resolutionn on resize |
| serviceDiscovery | plugin | unknown | not tested |
| timeSync | pkugin | unknown | not tested |
| vix | plugin | unknown | not tested |
| vmbackup | plugin | unknown | not tested |
| vmblock | filesystem | unknown | sharing mecanism for drag'n drop on or from desktop |
| vmhgfs | filesystem | unknown | file sharing on vmware workstation/fusion |
| vmmemctl | driver | unknown | memory controller for ballooning |
| vmxnet | driver | unknown | deprecated network driver |
| vmxnet3s | driver | unknown | paravirtualized network interface driver |

Requirements
------------
Minimum MacOS version will be 10.14

## MacOS 11.4 installed packages requirements
For build you will need to install XCode 11.3.1 (for MacOS 10.14) and homebrew with the following packages
| Build Dependencies | 
|:------------------:|
| `autoconf` |
| `automake` |
| `m4` |
| `gettext` | 
| `glib` |
| `libtool` |
| `libdnet` |


Installation
------------
pkg standard installation

Drivers
-------
tbd

Libraries
---------
The libappmonitor is compiled and instaled by the pkg. It is usefull to create a daemon to provide a heartbeat
for application monitoring in a vSphere HA configuration. Such a service may be released in the future to
detect system hang to make HA service to restart the VM (only useful on VMware clusters with HA enabled)
