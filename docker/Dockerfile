FROM ros:jazzy-ros-base-noble@sha256:103b6c417973394659af6804d4917cd489b91e5ed22eb7bef263025a3bed2410

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG ROS_GZ_VERSION=1.0.24-1noble.20261006.041805
ARG RVIZ_VERSION=14.1.24-1noble.20260915.204213
ARG CYCLONEDDS_VERSION=2.2.4-1noble.20260911.095700

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        "ros-jazzy-ros-gz=${ROS_GZ_VERSION}" \
        "ros-jazzy-rviz2=${RVIZ_VERSION}" \
        "ros-jazzy-rmw-cyclonedds-cpp=${CYCLONEDDS_VERSION}" \
        curl dbus-x11 fonts-dejavu-core libgl1-mesa-dri libxml2-utils \
        mesa-utils novnc openbox supervisor tint2 websockify \
        x11-utils x11vnc xterm xvfb \
    && dpkg-query -W -f='${Package}\t${Version}\n' > /opt/twinx-packages.tsv \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1001 --shell /bin/bash twin \
    && mkdir -p /home/twin/ws /home/twin/.config/openbox /data/recordings /data/results \
    && chown -R twin:twin /home/twin /data

COPY docker /opt/twinx/docker
COPY ros_ws/src /opt/twinx/src

RUN install -m 0755 /opt/twinx/docker/scripts/* /usr/local/bin/ \
    && install -m 0644 /opt/twinx/docker/desktop/menu.xml /home/twin/.config/openbox/menu.xml \
    && chown twin:twin /home/twin/.config/openbox/menu.xml \
    && for script in /opt/twinx/docker/scripts/*; do bash -n "$script" || exit; done \
    && find /opt/twinx/src /opt/twinx/docker -type f \
        \( -name '*.xml' -o -name '*.sdf' \) -exec xmllint --noout {} + \
    && printf '\nsource /opt/ros/jazzy/setup.bash\nsource /home/twin/ws/install/setup.bash\n' \
        >> /home/twin/.bashrc

ENV HOME=/home/twin \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

USER twin
WORKDIR /home/twin/ws
ENTRYPOINT ["/usr/local/bin/twinx-entrypoint"]
CMD ["twinx-desktop"]
