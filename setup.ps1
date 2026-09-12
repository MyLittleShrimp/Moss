$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$taskEngine = Join-Path $PSScriptRoot '.tools/godot/Godot_v4.6.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $taskEngine)) {
    New-Item -ItemType Directory -Force -Path '.tools' | Out-Null
    # Python HTTPS avoids a Windows Schannel credential failure on this host; certificate checks stay enabled.
    python -c "import urllib.request; urllib.request.urlretrieve('https://github.com/godotengine/godot-builds/releases/download/4.6.2-stable/Godot_v4.6.2-stable_win64.exe.zip', '.tools/godot.zip')"
    if ($LASTEXITCODE -ne 0) { throw 'Godot download failed; see docs/TROUBLESHOOTING.md.' }
    Expand-Archive -LiteralPath '.tools/godot.zip' -DestinationPath '.tools/godot' -Force
}
New-Item -ItemType File -Force -Path '.tools/godot/_sc_' | Out-Null
& $taskEngine --version
& $taskEngine --headless --path $PSScriptRoot --editor --import --log-file artifacts/import.log
exit $LASTEXITCODE
