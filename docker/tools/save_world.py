#!/usr/bin/env python3
"""Save scene layout, excluding the launch-managed Go2, into the Git working tree."""
import ast
import hashlib
from pathlib import Path
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET

TARGET = Path('/opt/twinx/src/twinx_bringup/worlds/lab.sdf')
MODELS = Path('/opt/twinx/models')


def save_scene(response):
    match = re.search(r'\bdata:\s*("(?:[^"\\]|\\.)*")', response, re.S)
    if not match:
        raise RuntimeError('Gazebo returned no SDF. Is the simulator running?')
    root = ET.fromstring(ast.literal_eval(match.group(1)))
    world = root.find('world')
    if world is None or world.get('name') != 'twinx_lab':
        raise RuntimeError('Expected the twinx_lab world; original file was not changed.')
    for model in list(world.findall('model')):
        if model.get('name') == 'go2':
            world.remove(model)  # Recreated from the versioned robot launch every startup.
    for uri in root.iter('uri'):
        value = (uri.text or '').strip()
        raw = value.removeprefix('file://')
        if raw.startswith('/opt/twinx/models/'):
            uri.text = 'model://' + raw.removeprefix('/opt/twinx/models/')
        elif raw.startswith('/opt/twinx/src/'):
            if not Path(raw).exists():
                raise RuntimeError(f'Missing project asset: {value}')
        elif raw.startswith('/'):
            source = Path(raw)
            if not source.exists():
                raise RuntimeError(f'Missing resource: {value}')
            # Copy the entire model to retain referenced textures and materials.
            base = next((p for p in source.parents if (p / 'model.config').exists()), None)
            if base is None:
                raise RuntimeError(f'Place this resource and its textures under assets/models first: {value}')
            digest = hashlib.sha256(str(base).encode()).hexdigest()[:12]
            dest = MODELS / ('imported_' + digest)
            # Docker Desktop bind mounts may reject chmod / metadata copying.
            for entry in base.rglob('*'):
                target = dest / entry.relative_to(base)
                if entry.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                elif entry.is_file():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(entry, target)
            uri.text = 'model://' + str((dest / source.relative_to(base)).relative_to(MODELS))
        elif value.startswith('model://'):
            if not (MODELS / value.removeprefix('model://')).exists():
                raise RuntimeError(f'Unbundled model resource: {value}; put it in assets/models first.')
        else:
            raise RuntimeError(f'Nonportable resource URI: {value}; bundle the asset under assets/models first.')
    original = ET.parse(TARGET).getroot().find('world')
    # Retain required systems even if Gazebo omits them from generated output.
    if world.find('spherical_coordinates') is None and original.find('spherical_coordinates') is not None:
        world.append(original.find('spherical_coordinates'))
    present = {p.get('name') for p in world.findall('plugin')}
    for plugin in original.findall('plugin'):
        if plugin.get('name') not in present:
            world.append(plugin)
    ET.indent(root)
    pending = TARGET.with_suffix('.sdf.tmp')
    ET.ElementTree(root).write(pending, encoding='utf-8', xml_declaration=True)
    shutil.copyfile(TARGET, TARGET.with_suffix('.sdf.bak'))
    pending.replace(TARGET)
    print('Saved lab.sdf and local model assets. Review git diff, then commit and push.')
    print('Go2 is managed by startup; its transient position is not saved.')


if __name__ == '__main__':
    try:
        response = subprocess.run([
            'gz', 'service', '-s', '/world/twinx_lab/generate_world_sdf',
            '--reqtype', 'gz.msgs.SdfGeneratorConfig', '--reptype', 'gz.msgs.StringMsg',
            '--timeout', '15000', '--req',
            'global_entity_gen_config { expand_include_tags { data: true } resources_use_absolute_paths { data: true } }'
        ], capture_output=True, text=True, check=True, timeout=25)
        save_scene(response.stdout)
    except Exception as error:
        raise SystemExit('Scene save failed: ' + str(error))
