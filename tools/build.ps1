param([ValidateSet('Release','Development')][string]$Channel = 'Release')
$ErrorActionPreference = 'Stop'
$mossRoot = Split-Path -Parent $PSScriptRoot
$mossTarget = Join-Path $mossRoot ('dist/Moss-' + $Channel)
New-Item -ItemType Directory -Path $mossTarget -Force | Out-Null
$mossEngine = Join-Path $mossRoot '.tools/godot/Godot_v4.6.2-stable_win64_console.exe'
& $mossEngine --headless --path $mossRoot --export-pack "Windows $Channel" (Join-Path $mossTarget 'game.zip') --log-file (Join-Path $mossRoot "artifacts/g10-build-$Channel.log")
if ($LASTEXITCODE -ne 0) { throw 'Godot export failed.' }
Copy-Item -LiteralPath (Join-Path $mossRoot '.tools/godot/Godot_v4.6.2-stable_win64.exe') -Destination (Join-Path $mossTarget 'Moss.exe')
Copy-Item -LiteralPath (Join-Path $mossRoot 'docs/third-party/GODOT-LICENSE.txt') -Destination $mossTarget
Copy-Item -LiteralPath (Join-Path $mossRoot 'docs/third-party/GODOT-COPYRIGHT.txt') -Destination $mossTarget
@'
@echo off
start "Moss and Moments" "%~dp0Moss.exe" --main-pack "%~dp0game.zip"
'@ | Set-Content -LiteralPath (Join-Path $mossTarget 'Start.cmd') -Encoding ASCII
@'
苔间小屋：解压整个文件夹后双击 Start.cmd。设置中填写自己的模型，默认不使用任何 Key。
设置 → 存档与搬家：新建、另存、加载、导出和导入。模型密钥与存档分开。
此便携包使用 Godot 4.6.2 完整运行二进制，包含编辑器代码，体积大于专用导出模板版。未签名。
Godot Engine MIT license: https://godotengine.org/license/
Godot third-party notices: https://github.com/godotengine/godot/blob/4.6.2-stable/COPYRIGHT.txt
'@ | Set-Content -LiteralPath (Join-Path $mossTarget '开始游玩.txt') -Encoding UTF8
Write-Output "BUILD_READY: $mossTarget"
