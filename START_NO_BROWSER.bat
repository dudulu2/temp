@echo off
chcp 65001 >nul
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel%==0 (py -3 run.py --no-browser & goto :eof)
where python >nul 2>nul
if %errorlevel%==0 (python run.py --no-browser & goto :eof)
echo Python 3 not found.
pause
