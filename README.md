# Ubuntu + Gazebo in your browser

Start Docker Desktop in **Linux containers** mode, then run from this folder:

```sh
docker compose up -d --build
```

Open [the Ubuntu desktop](http://localhost:6080/vnc.html?autoconnect=true&resize=scale).
The first build downloads Ubuntu, the XFCE desktop, and Gazebo; allow several minutes.
Open **Terminal Emulator** in the desktop and start Gazebo:

```sh
gz sim shapes.sdf
```

## Shared folder

The local `shared` folder is mounted at `/shared` inside Ubuntu. Both paths access
the same files: creating, editing, or deleting a file on either side appears on
the other side automatically while the container is running. No sync tool or
copy command is needed. Files remain on your computer after stopping or removing
the container. On Linux, the host folder must be writable by the container's
`ubuntu` user; a bind mount keeps host permissions.

## Versions and updates

The base is the official `ubuntu:latest` image (Docker's latest Ubuntu LTS tag).
Gazebo Jetty is the latest stable Gazebo release at the time this setup was written.
It is installed automatically during the image build; restarting the container
uses the installed copy. To fetch a newer Ubuntu image and current Jetty packages:

```sh
docker compose build --pull --no-cache
docker compose up -d
```

Gazebo packages must exist for the Ubuntu version behind `latest`. If a new Ubuntu
release arrives before Gazebo supports it, select the documented supported base
temporarily (PowerShell):

```powershell
$env:UBUNTU_IMAGE = 'ubuntu:24.04'
docker compose up -d --build
```

The desktop is available only from this computer on port 6080, without a password.
Software rendering is enabled so no GPU setup is required; complex simulations
may run slowly. Desktop settings and other files outside `/shared` are lost when
the container is recreated.

Stop with `docker compose down`. View startup output with `docker compose logs -f`.
