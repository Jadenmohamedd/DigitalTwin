# Ubuntu robotics desktop

A simple Docker desktop with **Ubuntu 24.04, ROS 2 Jazzy, Gazebo Harmonic,
and Nav2**. Includes RViz, ROS/Gazebo bridges, `gz_ros2_control`, and ROS build tools.
Packages install automatically during the build and are reused on restart.

See [QUICKSTART.md](QUICKSTART.md) for launching Gazebo and the Nav2 demo.

```sh
docker compose up --build -d
```

Open the [Ubuntu web desktop](http://localhost:6080/vnc.html?autoconnect=true&resize=scale).
ROS is loaded automatically in desktop terminals.

## Shared files

Local `shared/` is mounted directly at `/shared` in Ubuntu. Changes and deletions
on either side appear on the other automatically. Files survive container removal.
On Linux, the folder must be writable by the container's `ubuntu` user (UID 1000).
Keep work in `/shared`: other container files and desktop settings are lost on recreation.

## Updates and troubleshooting

The Ubuntu, ROS, and Gazebo release families are fixed for compatibility.
To install their latest available package updates:

```sh
docker compose build --pull --no-cache
docker compose up -d
```

Start Docker Desktop in **Linux containers** mode before running these commands.
The first build is large and may take several minutes. Use `docker compose logs -f`
for container output and `docker compose down` to stop.

The web desktop is restricted to this computer on port 6080, without a password.
Software rendering avoids GPU setup, though complex simulations may be slow.
Nav2 is installed with a TurtleBot demo; the shared Go2 project still requires its
own build, dependencies, and robot-specific navigation configuration.

Version pairing follows the [Gazebo ROS installation guide](https://gazebosim.org/docs/harmonic/ros_installation/).
The demo follows the [Nav2 quick start](https://docs.nav2.org/jazzy/getting_started/quickstart/quickstart/).
