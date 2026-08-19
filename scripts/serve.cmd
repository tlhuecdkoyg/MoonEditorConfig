@echo off
setlocal
cd /d "%~dp0.."
"D:\conda\environments\moonbit\moonbit-toolchain\bin\moon.exe" build --target js --release web/app
if errorlevel 1 exit /b %errorlevel%
"D:\conda\environments\moonbit\node.exe" tools\studio_server.mjs
