# whl-dbg

## Overview

`whl-dbg` provides the FRP-based networking and remote debugging setup for WheelOS vehicles. It establishes an outbound FRP connection from each vehicle to a bastion server and provides controlled remote access to the vehicle's SSH service through a per-vehicle server-side endpoint.

The repository contains Bash installers and management scripts for:

* Server-side `frps` service.
* Vehicle-side `frpc` client.
* Starting, stopping, and inspecting either process.
* Enabling or disabling systemd autostart for the vehicle-side client.
* SSH tunneling for accessing vehicle-local services such as DreamView.

The vehicle-side SSH service is bound to `127.0.0.1`, so the vehicle does not directly expose its SSH port to the external network.

## Role in WheelOS

This project belongs to the **Tools** category. It provides networking and remote debugging infrastructure and is not part of the vehicle runtime, perception, planning, control, or hardware stack.

```text
WheelOS
 |
 +--- Tools
      |
      +--- whl-dbg
```

## Architecture

```text
Developer Computer
        |
        | SSH
        | -p <vehicle_id + 60000>
        | -L 127.0.0.1:18888:127.0.0.1:8888
        v
Bastion / Server
  |
  +--- frps :7000
  |
  +--- 127.0.0.1:<vehicle_id + 60000>
        |
        | FRP tunnel
        v
Vehicle
  |
  +--- frpc
  |
  +--- 127.0.0.1:22
        |
        +--- SSH
        |
        +--- 127.0.0.1:8888
             |
             +--- DreamView / local service
```

The vehicle establishes the FRP connection to the server. The vehicle-side SSH service is configured on `127.0.0.1:22`.

For a numeric vehicle ID, the server-side SSH endpoint is calculated as:

```text
remotePort = 60000 + vehicle_id
```

The server configuration binds the proxy endpoint to `127.0.0.1`, keeping the per-vehicle SSH endpoint accessible only from the bastion host.

## Installation

The installers download the FRP 0.54.0 Linux binaries for `x86_64` or `aarch64`/`arm64`. The WheelOS mirror is used first, with the upstream GitHub release as a fallback.

Both installers require a Linux host.

### Server

Run on the bastion/server host:

```bash
sudo bash server/install.sh
```

The installer prompts for `auth.token` and installs to `/opt/frp/server` by default. Set `INSTALL_DIR` to use a different directory.

Manage the server:

```bash
bash server/manage.sh start
bash server/manage.sh status
bash server/manage.sh stop
```

### Vehicle

Run on the vehicle:

```bash
sudo bash car/install.sh
```

The installer prompts for:

* Server IP
* Vehicle ID
* `auth.token`

The vehicle client is installed to `/opt/frp/car` by default. Set `INSTALL_DIR` to use a different directory.

Manage the vehicle client:

```bash
bash car/manage.sh start
bash car/manage.sh status
bash car/manage.sh stop
```

Enable or disable systemd autostart:

```bash
bash car/manage.sh autostart on
bash car/manage.sh autostart off
bash car/manage.sh autostart status
```

## Examples

After the vehicle is connected, create an SSH tunnel from the developer computer:

```bash
ssh -N -T \
  -p <60000-plus-vehicle-id> \
  -L 127.0.0.1:18888:127.0.0.1:8888 \
  user@<server-ip>
```

Then open:

```text
http://127.0.0.1:18888
```

The local port `18888` is forwarded through the SSH session to the vehicle's `127.0.0.1:8888`.

Replace the placeholders with the server IP, SSH user, and vehicle port printed by the installer.

No other executable examples or application APIs are provided by this repository.

## Documentation

* [Vehicle Quick Start](car/README.md)
* [Apache License 2.0](LICENSE)
* [FRP upstream releases](https://github.com/fatedier/frp/releases)
