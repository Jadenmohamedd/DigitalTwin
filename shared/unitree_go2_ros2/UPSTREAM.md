# Upstream provenance

The Go2 and CHAMP packages in this directory are from
[khaledgabr77/unitree_go2_ros2](https://github.com/khaledgabr77/unitree_go2_ros2)
at commit `55ff151632a0220bf3ae0c0772392615d86da7a8`.

The repository has no declared top-level license. Its use here was authorized
by the project owner; this note does not grant redistribution rights. Retain
and follow licenses included with individual components, including CHAMP's
BSD license.

Do not use the upstream default simulation launch in TWINX: it starts another
Gazebo instance rather than joining the already-running `twinx_lab` world.
