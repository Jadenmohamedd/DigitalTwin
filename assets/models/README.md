# Project model assets

Place reusable custom models here, for example:

    my_obstacle/model.config
    my_obstacle/model.sdf
    my_obstacle/meshes/...
    my_obstacle/materials/...

Gazebo sees this folder as /opt/twinx/models in both containers. Reference models
with model://my_obstacle. Include all meshes, textures and applicable licenses.
Use Save world to repository after adding or moving objects in the running GUI,
then commit both this folder and the saved world. Downloads only in data/gazebo
remain local caches until the save helper bundles their referenced model assets.
