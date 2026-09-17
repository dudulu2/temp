@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo ============================================
echo   Agent Observatory - Read-only Sidecar
echo ============================================
echo.
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 run.py
  goto :eof
)
where python >nul 2>nul
if %errorlevel%==0 (
  python run.py
  goto :eof
)
echo [ERROR] Python 3 not found.
echo Install Python 3.11+ and run START.bat again.
pause
