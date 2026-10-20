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

## Set up the Go2 robot

The robot source is already in `shared/unitree_go2_ros2`; no download is needed.
With the container running, execute this in **PowerShell from the project folder**:

```powershell
docker compose exec --user root ubuntu bash /shared/setup_robot.sh
```

The script installs dependencies, builds the six robot packages as the Ubuntu
desktop user, and checks that ROS can find `unitree_go2_sim`. Wait for
**Robot setup finished**. If it stops, resolve the reported error before continuing;
the same command can be run again.

The first dependency installation and build may take a while. A warning about
running `rosdep update` as root is expected in the script's administrator shell.
Build output stays in `shared/build`, `shared/install`, and `shared/log`.
Installed system dependencies survive restarts, but rerun the script after
recreating the container.

## Launch the Go2 robot

Stop any standalone Gazebo instance or Nav2 demo first. Open a terminal in the
**Ubuntu browser desktop** and run:

```bash
source /shared/install/setup.bash
ros2 launch unitree_go2_sim unitree_go2_launch.py
```

This launches the robot simulation and RViz. The launch file delays controller
startup by about 20–30 seconds. Press **Ctrl+C** in its terminal to stop.
Run the `source` command in each new terminal before using the robot packages.

## Control Go2 with the keyboard

Keep the robot launch terminal running. In a **second Ubuntu desktop terminal**, run:

```bash
source /shared/install/setup.bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args -p speed:=0.2 -p turn:=0.5
```

Click inside this second terminal before pressing keys. The robot launch file
connects the controller to `/cmd_vel`, which is the keyboard tool's default topic.
Wait for the controllers to start, and make sure Gazebo is playing rather than paused.

| Key | Action |
| --- | --- |
| `i` | Forward |
| `,` | Backward |
| `j` / `l` | Turn left / right |
| `u` / `o` | Forward while turning left / right |
| `Shift+J` / `Shift+L` | Step sideways left / right |
| `k` | Stop movement |
| `q` / `z` | Increase / decrease movement and turn speeds |
| `Ctrl+C` | Stop movement and exit keyboard control |

Press `k` to stop; releasing a movement key alone does not send a stop command.
Press **Ctrl+C** in the first terminal when you want to stop the entire simulation.

If the robot does not move, open another Ubuntu terminal and check:

```bash
source /shared/install/setup.bash
ros2 control list_controllers
```

Both `joint_states_controller` and `joint_group_effort_controller` should be `active`.
If either is missing or inactive, inspect the robot launch terminal for errors.
Key mappings and speed parameters follow the
[ROS keyboard teleoperation guide](https://github.com/ros2/teleop_twist_keyboard/blob/rolling/README.md).

## Try the separate Nav2 demo

Stop the standalone Gazebo instance first. In an Ubuntu desktop terminal, run:

```sh
ros2 launch nav2_bringup tb3_simulation_launch.py headless:=False
```

This starts a TurtleBot demo with Gazebo, RViz, and Nav2. In RViz, use
**2D Pose Estimate** to set the robot's starting pose, then the navigation goal
tool to select a destination. This demo is separate from the shared Go2 project,
which still needs its own robot-specific navigation configuration.

## Stop or inspect

Run these from the project folder on your computer:

```sh
docker compose down       # Stop; shared files remain
docker compose logs -f    # View container output; Ctrl+C exits
```

`docker-compose.yml` configures the service; `container/` contains the image and
desktop setup. See [README.md](README.md) for updates and troubleshooting.
