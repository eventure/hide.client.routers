# hide.me VPN for Routers

## General

Support for hide.me VPN WireGuard protocol on OpenWrt devices with specific variants for GL.iNet devices.

OpenWrt implementation defines new protocol "hide.me VPN WireGuard" that integrates support for hide.me VPN's specific WireGuard protocol handling.

GL.iNet specific variants patch system to add hide.me VPN's WireGuard support into GL.iNet's custom WireGuard implementation.

That allows a nice integration with GL.iNet UI with support for official enabling/disabling VPN connection, showing VPN status in UI and does not need to install LuCI and use "advanced" settings.

GL.iNet firmware with version 3 or 4 is needed and device must have included WireGuard support.

Due to a different implementations between firmwares v3 and v4, there are two different scripts and it is important to use script with support for v3 firmware on a device with v3 and same with firmware v4.

NOTE: On GL.iNet is possible to use pure OpenWrt implementation. Only one script type, GL.iNet or OpenWrt, can be used at the same time on the GL.iNet device. It is not possible to mix or use both.


## Installation

Installation is done using SSH:

```curl -fsSL https://raw.githubusercontent.com/eventure/hide.client.openwrt/master/VARIANT/hidemevpn | sh -s install```

Where VARIANT is one of the following values: openwrt, glinet_v3, glinet_v4 VARIANT depends on the router type and preferred version to be used.

Variant openwrt supports all OpenWrt 18.06 and newer devices. Variants glinet_v3 and glinet_v4 are specific to GL.iNet specific devices.

How to connect to a device using SSH can be found on the following links:

* https://openwrt.org/docs/guide-quick-start/sshadministration
* https://docs.gl-inet.com/en/3/tutorials/ssh/

Check section "Login (full URLs)" below for installation commands for all variants.

During installation it will ask for login and password and it will try to fetch access token.

NOTE: Only access token is saved. Access token is automatically refreshed when needed and possible. When access token becomes invalid connection won't be possible and login must be done again (check section "Login")

Update of the script is done by starting install again. Settings will be preserved.


## Uninstall

Uninstall is done using SSH:

`hidemevpn uninstall`

That will remove script itself, all changes in the system, related files and configuration.


## Login

When needed to change or refresh credentials login must be performed:

`hidemevpn login`

Login does not store username and password. Only access token is stored. If access token becomes obsolete login must be repeated to obtain new access token.


## Servers/locations list

List of available servers/locations is refreshed automatically every 24h hours (once a day).

Manual changes in the automatically defined server won't be preserved between updates.

NOTE: On GL.iNet devices with firmware v4 it is not advised to define servers under the same group with automatically defined servers.


## Creating connection (OpenWrt)

Here is an example how to create a new Hide.me WG interface and select location in LuCI web admin interface:
1. Select Network->Interfaces
2. Click "Add new interface..."
3. Input name of the new interface under "Name of the new interface", for example wghide
4. Select "hide.me VPN WireGuard" in "Protocol of the new interface"
5. Click "Submit"
6. Then under interface select location under "Location" and click "Save" or "Save & Apply"
7. Later, location can be changed using "Edit" on the interface

Although it is possible to create multiple interfaces that is not recommended and it won't work as our connection currently sets to be a default route for all traffic.

Multiple connections will clash at least with routes.

If servers list cannot be fetched it will be empty. In that case only solution is to set location manually from command line on  the device itself. Check section "Custom server (OpenWrt)"


## Custom server (OpenWrt)

If there is a need to connect to a specific or unlisted server, that can be done by setting UCI parameter server, like:

`uci set network.wghide.server="us.hideservers.net"`

`uci commit network`

## Custom server (GL.iNet)

It is possible to define new connection manually using GL.iNet's UI.

Any server defined with endpoint host on domain hideservers.net will be processed as hide.me VPN's server.

All other values are not important and can be set to some dummy values, for non optional ones.

Key related fields can be populated with a dummy all zero key value:
```AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=```


## Install (full URLs)

OpenWrt:

```curl -fsSL https://raw.githubusercontent.com/eventure/hide.client.routers/master/openwrt/hidemevpn | sh -s install```

GL.iNet v3:

```curl -fsSL https://raw.githubusercontent.com/eventure/hide.client.routers/master/glinet_v3/hidemevpn | sh -s install```

GL.iNet v4:

```curl -fsSL https://raw.githubusercontent.com/eventure/hide.client.routers/master/glinet_v4/hidemevpn | sh -s install```


## Logging
-------

Script logs certain events with tag "hidemevpn".
To see all related log entries use:

`logread -e hidemevpn:`

NOTE: if semicolon is ommited output will be include some hidemevpn related 
log entries from cron


## Other remarks

For everything that is not mentioned here, please check source code on 
Github:

https://github.com/eventure/hide.client.routers
