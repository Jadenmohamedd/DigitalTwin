$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path (Join-Path $root ".env"))) {
    Copy-Item (Join-Path $root ".env.example") (Join-Path $root ".env")
}

$secretDirectory = Join-Path $root ".secrets"
New-Item -ItemType Directory -Path $secretDirectory -Force | Out-Null
$passwordFile = Join-Path $secretDirectory "vnc_password"
if (-not (Test-Path $passwordFile)) {
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $bytes = New-Object byte[] 12
        $random.GetBytes($bytes)
        $password = [Convert]::ToBase64String($bytes).Substring(0, 8)
        [System.IO.File]::WriteAllText(
            $passwordFile, $password, (New-Object System.Text.UTF8Encoding $false))
    }
    finally {
        $random.Dispose()
    }
}

foreach ($directory in @("data\recordings", "data\results")) {
    New-Item -ItemType Directory -Path (Join-Path $root $directory) -Force | Out-Null
}

Write-Host "Local environment and VNC secret are ready. Existing files were preserved."
Write-Host "Build: docker compose --profile gui build simulator"
Write-Host "Start: docker compose --profile gui up -d --wait --wait-timeout 180"
Write-Host "Read the VNC password locally: Get-Content .\.secrets\vnc_password"
