param(
    [string]$Storage = 'D:\STORAGE\SAM\KOSMOS3D_UPLOADS',
    [int]$Port = 8787
)
$ErrorActionPreference = 'Stop'
$configFolder = Join-Path $env:LOCALAPPDATA 'KOSMOS3D'
New-Item -ItemType Directory -Force -Path $configFolder | Out-Null
$tokenPath = Join-Path $configFolder 'receiver-token.txt'
if (-not (Test-Path -LiteralPath $tokenPath)) {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    [Convert]::ToBase64String($bytes) | Set-Content -LiteralPath $tokenPath -NoNewline
    & icacls.exe $tokenPath /inheritance:r /grant:r "$($env:USERNAME):(F)" | Out-Null
}
$env:KOSMOS_TRANSFER_TOKEN = (Get-Content -LiteralPath $tokenPath -Raw).Trim()
try {
    python -u (Join-Path $PSScriptRoot 'kosmos_receiver.py') --host 0.0.0.0 --port $Port --root $Storage
} finally { Remove-Item Env:KOSMOS_TRANSFER_TOKEN }
