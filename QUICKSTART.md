# Quick start

Ubuntu **24.04** + ROS 2 **Jazzy** + Gazebo **Harmonic** + **Nav2**, with a browser desktop.

## Start the desktop

1. Open Docker Desktop in **Linux containers** mode.
2. From this project folder, run:

   ```sh
   docker compose up --build -d
   ```

3. Wait for the build to finish, then open the
   [Ubuntu desktop](http://localhost:6080/vnc.html?autoconnect=true&resize=scale).
4. Open **Terminal Emulator** inside Ubuntu. ROS 2 is loaded automatically.

## Launch Gazebo

```sh
gz sim shapes.sdf
```

Local `shared/` is available as `/shared` in Ubuntu. Both access the same files,
so edits and deletions appear on both sides automatically. To open your own world:

```sh
gz sim /shared/my_world.sdf
```

Replace `my_world.sdf` with your file name. Press **Ctrl+C** in the terminal to stop.

## Try Nav2

Stop the standalone Gazebo instance first. In an Ubuntu desktop terminal, run:

```sh
ros2 launch nav2_bringup tb3_simulation_launch.py headless:=False
```

This starts a TurtleBot demo with Gazebo, RViz, and Nav2. In RViz, use
**2D Pose Estimate** to set the robot's starting pose, then the navigation goal
tool to select a destination. This demo is separate from the shared Go2 project,
which still needs its own build and navigation configuration.

## Stop or inspect

Run these from the project folder on your computer:

```sh
docker compose down       # Stop; shared files remain
docker compose logs -f    # View container output; Ctrl+C exits
```

`docker-compose.yml` configures the service; `container/` contains the image and
desktop setup. See [README.md](README.md) for updates and troubleshooting.
