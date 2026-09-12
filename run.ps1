param([string]$GodotPath, [switch]$Editor, [switch]$Test, [switch]$VisualQA)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (-not $GodotPath) { $GodotPath = Join-Path $PSScriptRoot '.tools/godot/Godot_v4.6.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Godot not found. Run setup.ps1 or pass -GodotPath with the path to Godot 4.6.2.' }
if ($Test) {
    & $GodotPath --headless --path $PSScriptRoot --script res://tests/test_world.gd --log-file artifacts/g3-world-tests.log
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $GodotPath --headless --path $PSScriptRoot --script res://tests/test_expansion.gd --log-file artifacts/g5-world-tests.log
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $GodotPath --headless --path $PSScriptRoot --script res://tests/test_living.gd --log-file artifacts/g6-rules.log
} elseif ($VisualQA) {
    & $GodotPath --path $PSScriptRoot --log-file artifacts/g6-ui-regression.log -- --qa
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $GodotPath --path $PSScriptRoot res://tests/living_scene.tscn --log-file artifacts/g6-ui-qa.log -- --qa
} elseif ($Editor) {
    & $GodotPath --editor --path $PSScriptRoot
} else {
    & $GodotPath --path $PSScriptRoot
}
exit $LASTEXITCODE
