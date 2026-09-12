@echo off
setlocal
set "MOSS_ENGINE=%~dp0.tools\godot\Godot_v4.6.2-stable_win64.exe"
if not exist "%MOSS_ENGINE%" (
  echo Godot is missing. Run setup.ps1 first.
  pause
  exit /b 1
)
start "Moss and Moments - Release Preview" "%MOSS_ENGINE%" --path "%~dp0." -- --release-pace
