#!/usr/bin/env bash
# Run from host PowerShell in the project folder:
# docker compose exec --user root ubuntu bash /shared/setup_robot.sh
set -Ee -o pipefail
trap 'echo "Setup stopped at line $LINENO. Fix the error above, then run this script again." >&2' ERR

workspace="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
robot_source="$workspace/unitree_go2_ros2"

if [[ "$EUID" -ne 0 ]]; then
  echo 'Run this from PowerShell in the project folder:' >&2
  echo 'docker compose exec --user root ubuntu bash /shared/setup_robot.sh' >&2
  exit 1
fi

if [[ ! -f /opt/ros/jazzy/setup.bash || ! -d "$robot_source" ]]; then
  echo 'This script needs the Jazzy container and unitree_go2_ros2 beside it in /shared.' >&2
  exit 1
fi

source /opt/ros/jazzy/setup.bash
export DEBIAN_FRONTEND=noninteractive

echo '== Installing robot dependencies =='
apt-get update
apt-get install -y \
  ros-jazzy-robot-localization \
  ros-jazzy-ros2-controllers \
  ros-jazzy-velodyne-description \
  ros-jazzy-teleop-twist-keyboard

if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
  rosdep init
fi
# This administrator shell owns the rosdep cache used for package installation.
rosdep update --rosdistro jazzy
rosdep install --from-paths "$robot_source" --ignore-src --rosdistro jazzy -y

echo '== Building as the Ubuntu desktop user =='
# Keep build files owned by the desktop user, rather than root.
runuser -u ubuntu -- bash -c '
  set -e -o pipefail
  source /opt/ros/jazzy/setup.bash
  cd -- "$1"
  colcon build --base-paths unitree_go2_ros2 --parallel-workers 2
  source install/setup.bash
  ros2 pkg prefix unitree_go2_sim
' bash "$workspace"

echo
echo 'Robot setup finished. In an Ubuntu desktop terminal, run:'
printf 'source %q/install/setup.bash\n' "$workspace"
echo 'ros2 launch unitree_go2_sim unitree_go2_launch.py'
echo
echo 'Build files stay in /shared. Re-run this script after recreating the container.'
