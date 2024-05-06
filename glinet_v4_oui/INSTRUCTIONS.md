# hide.me VPN for GL.iNet v4 OUI

This directory contains implementation of OUI RPC interface for GL.iNet devices based on firmware v4.

It is not intended to be used by end users.
For end user script please see [README.md](https://github.com/eventure/hide.client.routers/) for instructions.

## Installation

Install required files on device:

```
cp hidemevpn /usr/sbin/hidemevpn
cp hidemevpn.lua /usr/lib/oui-httpd/rpc/hidemevpn
```

## Usage

It should be used from UI as described in [official OUI documentation](https://zhaojh329.github.io/oui/guide/).

All APIs are documented in hidemevpn.lua file.

For testing purposes, it is possible to use test.sh script from command line that will send requests with curl and display raw output.

Script must be configured with valid URL and session ID (SID).

That must be done by copying config.sample to a new file named config, put in the same directory where test.sh is, and update URL and SID values.

Running test.sh without arguments will reveal all possible commands that directly translate to the OUI RPC APIs.

Warning! Please beware that input values are not validated, and neither are escaped when encoding to JSON!
