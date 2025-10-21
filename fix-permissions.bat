@echo off
echo Fixing /usr/local permission issues for YADS
echo ===========================================
echo.
echo This script will fix permission issues that prevent YADS from working properly.
echo.
echo Prerequisites:
echo - You need to be running this on a Linux system (not Windows)
echo - You need sudo/root access
echo - YADS should be installed
echo.
echo If you're on Windows, you need to:
echo 1. Use WSL (Windows Subsystem for Linux)
echo 2. Or run this on a Linux server/VM
echo.
echo To run this script:
echo   sudo ./fix-usr-local-permissions.sh
echo.
echo This will:
echo - Fix /usr/local permissions
echo - Fix VS Code Server permissions
echo - Start VS Code Server service
echo - Test that everything works
echo.
pause
