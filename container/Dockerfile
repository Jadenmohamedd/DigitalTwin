FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    LANG=C.UTF-8 \
    ROS_DISTRO=jazzy \
    LIBGL_ALWAYS_SOFTWARE=1 \
    QT_X11_NO_MITSHM=1 \
    XDG_RUNTIME_DIR=/tmp/runtime-ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    xfce4 xfce4-terminal dbus-x11 \
    xvfb x11vnc x11-utils novnc websockify supervisor \
    libgl1-mesa-dri mesa-utils \
    && rm -rf /var/lib/apt/lists/*

# Jazzy's ros-gz package supplies Gazebo Harmonic via ROS vendor packages.
RUN curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
      -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu noble main" \
      > /etc/apt/sources.list.d/ros2.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
      ros-jazzy-desktop ros-jazzy-ros-gz \
      ros-jazzy-navigation2 ros-jazzy-nav2-bringup \
      ros-jazzy-nav2-minimal-tb3-sim ros-jazzy-gz-ros2-control \
      python3-colcon-common-extensions python3-rosdep build-essential git \
    && rm -rf /var/lib/apt/lists/*

RUN id ubuntu >/dev/null 2>&1 || useradd --create-home --shell /bin/bash ubuntu
RUN mkdir -p /shared /tmp/runtime-ubuntu \
    && chown ubuntu:ubuntu /shared /tmp/runtime-ubuntu \
    && chmod 700 /tmp/runtime-ubuntu

RUN echo '. /opt/ros/jazzy/setup.bash' >> /home/ubuntu/.bashrc
COPY supervisord.conf /etc/supervisor/desktop.conf
USER ubuntu
WORKDIR /shared
EXPOSE 6080
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
    CMD curl -fsS http://localhost:6080/vnc.html >/dev/null && xdpyinfo >/dev/null
CMD ["/bin/bash", "-c", "source /opt/ros/jazzy/setup.bash && exec supervisord -c /etc/supervisor/desktop.conf"]
