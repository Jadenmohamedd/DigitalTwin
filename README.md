# TWINX: initial Docker environment

Ubuntu 24.04 + ROS 2 Jazzy + Gazebo Harmonic, with an authenticated, browser-accessible
Linux desktop and RViz. Go2 is automatically spawned into the laboratory with its controller bringup.
**It is not yet a validated autonomous navigation prototype.**

The simulator runs an original, primitive-only 8 m x 6 m laboratory with walls, a
static obstacle, and visual markers for a future start and goal. The vendored Go2 model is loaded locally; no external
models are downloaded at startup.

## Prerequisites

- Windows, Docker Desktop, **Linux containers**, and the **WSL 2 backend**.
- Docker Compose v2 with `up --wait` support.
- At least 8 GB assigned to Docker is recommended; allow several GB of disk space
  and internet access for the first image build.
- Run the commands below in PowerShell from this repository's root.

## First launch

```powershell
Set-Location C:\MyFiles\Github\DigitalTwin
powershell -ExecutionPolicy Bypass -File .\scripts\Initialize-Project.ps1
docker compose --profile gui config --quiet
docker compose up --build -d
docker compose ps
Get-Content .\.secrets\vnc_password
Start-Process "http://localhost:8080/vnc.html?autoconnect=1&resize=scale"
```

Enter the generated VNC password in the browser. RViz opens automatically.
The supervised RViz window reopens if closed.
Right-click the desktop background for a **ROS 2 terminal** or **Gazebo GUI**.
The Gazebo GUI connects to the already-running simulator; it does not start
another server. You can also launch it from PowerShell:

```powershell
docker compose exec -d desktop twinx-gazebo
```

RViz initially shows a grid only: the world is visualized in **Gazebo**, not
automatically in RViz. Set RViz Fixed Frame to `odom` to inspect robot-relative data.
No placeholder map transform is published; localization is a later milestone.

The initializer preserves existing settings and secrets. Edit `.env` to change
`WEB_PORT`, `ROS_DOMAIN_ID` (use 0-101), or desktop dimensions, then recreate with
`docker compose up -d --wait`. If the port changes, adjust the browser URL.

### Authentication and access

Only `127.0.0.1:8080` is published. VNC port 5900 and the X display are not
published; X11 uses only a Unix socket inside the desktop container.

The password lives in ignored `.secrets\vnc_password`, mounted as a Compose
secret, never built into an image or placed in a URL. Classic VNC accepts only
8 characters; the initializer generates 8 random base64 characters. To rotate it,
write exactly 8 printable ASCII characters without a newline and restart desktop:

```powershell
# Enter a new value without echoing it or adding it to command history.
$secret = Read-Host "New 8-character VNC password" -AsSecureString
$credential = New-Object System.Net.NetworkCredential("", $secret)
[System.IO.File]::WriteAllText(
    (Join-Path $PWD ".secrets\vnc_password"), $credential.Password,
    (New-Object System.Text.UTF8Encoding $false))
docker compose restart desktop
```

This local-only HTTP/VNC baseline is not encrypted and must not be published on a
LAN or the internet. Remote access needs a separately secured TLS/authentication
gateway or tunnel. Anyone with local Docker access already controls containers.

## Services, profiles, and discovery

| Service | Profiles | Responsibility |
| --- | --- | --- |
| `simulator` | `sim`, `gui` | Headless Harmonic server, laboratory world, Gazebo-to-ROS `/clock` bridge |
| `desktop` | `gui` | Xvfb, Openbox, task panel, x11vnc, noVNC/websockify, RViz; optional Gazebo GUI |

Both services share one dependency image to keep the initial setup small and
consistent. Both run as unprivileged user `twin` (UID 1001), without a privileged
container, host networking, Docker socket, or host X server.

ROS uses Cyclone DDS on the Compose bridge network. Multicast is disabled for DDS;
each participant contacts Docker DNS name `simulator` plus local participants.
Asymmetric unicast discovery allows the simulator to discover the desktop back.
Use the same `ROS_DOMAIN_ID` everywhere. Gazebo transport is separate from ROS:
its server and GUI share `GZ_PARTITION=twinx` and bridge-network multicast.
Recreate/restart clients if the simulator is recreated with a different IP.

All GUI processes share **desktop's local `DISPLAY=:0`**. The headless simulator
does not need an X connection. This avoids mounting X sockets between containers.
RViz uses simulation time; both health checks require receiving `/clock` within
a bounded timeout. Desktop additionally checks HTTP, X display, and RViz.
X clients wait for display readiness, not just a fixed startup sleep.

The initializer creates `.env` from `.env.example`, which defaults to
`COMPOSE_PROFILES=gui`. This makes `docker compose up --build -d` build and start
the browser stack with no extra profile or build-argument flags. For headless-only
operation, explicitly override that default:

```powershell
docker compose --profile sim up -d --wait
# To change from an already-running GUI stack to headless-only:
docker compose --profile gui stop desktop
```

An explicit `--profile sim` overrides `COMPOSE_PROFILES=gui`. There is deliberately
no fake `autonomy` service or `benchmark` profile yet. Add those once real
localization, Nav2, reset semantics, and experiment execution are implemented.
No hardware backend or fake hardware driver is supplied.

## Checks and development

```powershell
docker compose --profile gui config --quiet
docker compose ps
docker compose logs --tail 100 simulator desktop
docker compose exec simulator bash -lc "source /home/twin/ws/install/setup.bash; ros2 pkg prefix twinx_bringup"
docker compose exec simulator bash -lc "source /home/twin/ws/install/setup.bash; ros2 launch twinx_bringup simulation.launch.xml --show-args"
docker compose exec desktop bash -lc "source /home/twin/ws/install/setup.bash; timeout 15 ros2 topic echo /clock rosgraph_msgs/msg/Clock --once --qos-reliability best_effort"
docker compose exec desktop bash -lc "glxinfo -B"
docker compose exec desktop supervisorctl -c /opt/twinx/docker/desktop/supervisord.conf status
```

`ros_ws\src` is bind-mounted read-only inside the containers but editable on the
host. The entrypoint builds local packages using `colcon --symlink-install`;
each service has its own build/install volume. Restart the affected service after
source changes. Editing the world or ROS configuration does not rebuild OS/ROS
dependencies. Changes under `docker` require rebuilding the image.

### Verification on this machine (2026-10-18)

| Check | Result |
| --- | --- |
| Compose configuration and `sim`/`gui` profile selection | Passed |
| PowerShell initializer syntax, idempotence, and secret format | Passed |
| Image build, Bash syntax checks, XML/SDF well-formedness | Passed |
| ROS bringup package build and launch argument parsing | Passed |
| Headless Gazebo Harmonic server | Running, healthy |
| `/clock` received in the separate desktop container | Passed |
| RViz, Xvfb, window manager, VNC, and web proxy processes | Running |
| Mesa software rendering | llvmpipe, OpenGL 4.5 |
| Browser HTTP and WebSocket connection | Passed; browser requests VNC credentials |
| VNC authentication and framebuffer initialization | Passed, 1440 x 900 |
| Gazebo GUI discovery and window creation on the desktop | Passed, Gazebo Sim 8.15.0 |
| Robot sensors, TF, AMCL, Nav2, and navigation benchmark | Not implemented or tested |
| NVIDIA rendering and physical hardware | Not tested |

The browser was left at the password prompt; authentication was checked
separately against the VNC server without printing the secret. These are
infrastructure checks, not an end-to-end navigation success claim.

Scripts are checked with `bash -n`, and XML/SDF with `xmllint`, during image build.
The base image is digest-pinned; direct `ros_gz`, RViz, and Cyclone DDS package
versions are pinned to Ubuntu Noble `amd64` repository candidates verified on
2026-10-19. Transitive
Ubuntu/ROS packages are **not** snapshot-pinned. The installed version inventory
is `/opt/twinx-packages.tsv`; if a pinned package leaves the live repository,
select a compatible published version explicitly rather than silently unpinning it.

```powershell
# Capture actual versions and the local image identifier outside container storage.
docker compose exec -T simulator cat /opt/twinx-packages.tsv |
    Set-Content .\data\results\software-packages.tsv
docker image inspect twinx-dev:jazzy-harmonic --format "{{.Id}}" |
    Set-Content .\data\results\image-id.txt
```

## Data and shutdown

Recordings and results are bind-mounted at `/data/recordings` and `/data/results`,
backed by `data\recordings` and `data\results` on Windows. No experiment recording
or metrics are generated automatically in this initial setup.

```powershell
Get-ChildItem .\data\recordings
Get-ChildItem .\data\results
docker compose --profile gui --profile sim down
```

`down` stops the stack without deleting host data or workspace volumes. Do not
add `-v` unless you intentionally want to discard generated build/install caches.

## Rendering and troubleshooting

- **Build fails with `Version '...' was not found`:** ROS Debian build versions
  can differ by architecture and can leave the live repository after a sync.
  Check the published candidates using the same base image as the Dockerfile:
  `docker run --rm ros:jazzy-ros-base-noble@sha256:103b6c417973394659af6804d4917cd489b91e5ed22eb7bef263025a3bed2410 bash -c "apt-get update -qq && apt-cache policy ros-jazzy-ros-gz ros-jazzy-rviz2 ros-jazzy-rmw-cyclonedds-cpp"`.
  Update the corresponding version arguments in `docker/Dockerfile` to compatible
  published versions, then retry `docker compose up --build -d`.
- **ROS discovery:** compare `ROS_DOMAIN_ID`, `RMW_IMPLEMENTATION`, and
  `CYCLONEDDS_URI` in both containers. Check `docker compose logs simulator`.
  ROS tools on the Windows host are not automatically connected to this network;
  use the desktop terminal or `docker compose exec`. Recreate clients after
  changing the simulator's network address.
- **Missing transforms / Nav2 inactive:** expected at this stage: there is no
  robot, odometry, laser, localization, map server, or Nav2 lifecycle yet.
  A healthy clock does not certify navigation readiness.
- **Black desktop:** check `supervisorctl ... status` and desktop logs. Confirm the
  browser connected and accepted the password. Check that Xvfb and x11vnc are
  running; reconnect after restarting desktop. Do not expose host X11 as a fix.
  Ubuntu's packaged noVNC may log a `package.json` 404 for optional version
  metadata; this does not prevent the VNC connection or desktop display.
- **Rendering:** `LIBGL_ALWAYS_SOFTWARE=1` selects Mesa software rendering.
  `glxinfo -B` should report llvmpipe. Lower desktop dimensions or close Gazebo GUI
  if rendering is slow; the server continues headlessly. No GPU is required.
  NVIDIA GPU/OpenGL passthrough has not been configured or verified. CUDA/compute
  availability alone does not prove that Xvfb, GLX, RViz, or Gazebo can render on
  a GPU, so no speculative GPU override is supplied.
- **Mounted-file permissions:** enable Docker Desktop access to this directory.
  Windows bind-mount permissions differ from native Linux. Runtime code does not
  recursively chmod/chown the repository. On Linux, grant UID 1001 write access
  specifically to data directories. Secrets must be readable by the container.
- **Build/package failures:** verify internet access and the Docker Desktop proxy.
  Package versions are installed only while building, not on container startup.
- **Unhealthy simulator:** inspect logs and verify `/clock` with the command above.
  Increasing startup time will not fix a crashed server or a DDS configuration
  error. `docker inspect` includes the exact health-check failure output.

## Scope boundary and next milestone

Delivered here: Compose, images/scripts, authenticated browser desktop, software
rendering, RViz, initial Gazebo laboratory, ROS clock bridge, editable ROS bringup
package, and persistent data locations.

Still to implement from `requirements.md`:

1. A maintained, explicitly temporary differential-drive robot in a separate
   robot-specific package; simulated laser/odometry/joints and command bridge.
2. A matching occupancy map, robot description, nonduplicated
   `map -> odom -> base_link -> sensor` transforms, AMCL, initial-pose readiness,
   and Nav2. Verify Jazzy's actual `Twist`/`TwistStamped` configuration.
3. Separate `autonomy` service and on-demand `benchmark` service/profile, bounded
   readiness checks for sensors/TF/localization/Nav2, reproducible resets,
   recording, and machine-readable estimated metrics.
4. End-to-end navigation around the obstacle with a successful recorded trial.

There are intentionally no manual-navigation or benchmark commands to run yet.
No collision or ground-truth metrics, navigation success, Unitree locomotion,
or sim-to-real performance are claimed. Replacing the temporary robot later with
a Go2/G1 requires a compatible model, functioning locomotion controller,
consistent frames/sensor/command interfaces, and a real hardware interface.
The world and infrastructure package can remain independent of that choice.

## Verified upstream references and asset provenance

- [ROS 2 Jazzy Ubuntu deb installation](https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html):
  Ubuntu Noble 24.04 and Jazzy binary packages.
- [Gazebo/ROS compatibility and installation](https://gazebosim.org/docs/harmonic/ros_installation/):
  Jazzy + Harmonic and `ros-jazzy-ros-gz`, not Gazebo Classic.
- [ROS/Gazebo bridge](https://docs.ros.org/en/jazzy/p/ros_gz_bridge/):
  clock message conversion and bridge configuration.
- [Cyclone DDS unicast discovery](https://cyclonedds.io/docs/cyclonedds/latest/config/discovery-config.html):
  peers and asymmetric discovery.
- [noVNC deployment](https://novnc.com/noVNC/docs/EMBEDDING.html):
  web files, WebSocket proxy, and connection settings.
- [Compose profiles](https://docs.docker.com/compose/how-tos/profiles/).

The laboratory consists of original SDF primitives. Go2 and CHAMP sources are
vendored under `ros_ws/src/unitree_go2_ros2`; see its UPSTREAM.md and component
license notices. ROS/RViz/ros_gz and the new bringup package use Apache-2.0;
Gazebo dependencies carry their upstream licenses. noVNC is MPL-2.0, websockify
is LGPL-3.0, Openbox is GPL-2.0+, and x11vnc is GPL-2.0+. Exact distro notices are
retained in `/usr/share/doc/<package>/copyright` inside the image.

## Go2 startup and sharing scene edits

Go2 now spawns automatically in `twinx_lab` at (-2, -1.5, 0.375).
The launch in `ros_ws/src/twinx_bringup/launch/go2.launch.py` owns robot spawning,
CHAMP, estimation and joint controller activation. Gazebo still has one server.
The cameras and 3D LiDARs are disabled initially for software rendering performance.
This provides robot bringup; walking and navigation still require runtime validation.

Commit and push the integration changes first. After pulling on another device:

```powershell
git pull
powershell -ExecutionPolicy Bypass -File .\scripts\Initialize-Project.ps1
docker compose --profile gui up -d --build --force-recreate
```

World files are stored in `ros_ws/src/twinx_bringup/worlds/` and custom model
assets in `assets/models/`. Both are mounted directly from the repository.
World changes made by editing `lab.sdf` take effect after restarting simulator.
To persist objects added/moved/deleted in the Gazebo GUI, save BEFORE restarting.
Right-click the desktop background and select **Save world to repository**, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Save-World.ps1
git diff -- ros_ws/src/twinx_bringup/worlds/lab.sdf
git add ros_ws/src/twinx_bringup/worlds assets/models
# Review the staged changes before choosing your commit message.
git commit -m "Save laboratory layout"
git push
```

The save command exports the current scene, removes the launch-managed Go2 to
avoid duplicate robots, and writes `lab.sdf` with a local `.sdf.bak` backup.
Robot spawn coordinates belong in `go2.launch.py`; they are not saved from the
moving simulation. Save while the scene is paused if other dynamic objects matter.
This is a layout snapshot, not a controller/physics checkpoint or full GUI settings backup.
No automatic Git commits or pushes occur.

Fuel/cache downloads persist locally in ignored `data/gazebo/`. The save helper
copies referenced cached models (including textures) into tracked `assets/models/`
when a model.config root is available, and replaces their URIs with model:// paths.
If an asset cannot be made portable, saving fails rather than overwriting the world
with an unusable path. Put custom models and all their textures in assets/models
before inserting them. Commit those files to share them; a cache folder alone
will not transfer through Git. Check third-party asset redistribution permissions.
Large assets may need Git LFS configured on every device.

Recordings/results remain local under data/ and are ignored by Git. Build/install
volumes are disposable generated files; they do not define the saved scene.
Never use `docker compose down -v` as a routine update step.
