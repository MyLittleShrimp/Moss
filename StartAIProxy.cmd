@echo off
setlocal
cd /d "%~dp0"
python server\proxy.py
pause
