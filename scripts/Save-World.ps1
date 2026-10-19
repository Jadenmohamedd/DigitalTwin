$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    docker compose exec -T simulator bash -lc "source /opt/ros/jazzy/setup.bash; python3 /opt/twinx/docker/tools/save_world.py"
    if ($LASTEXITCODE -ne 0) { throw 'World saving failed. See the error above.' }
    git status --short
} finally { Pop-Location }

