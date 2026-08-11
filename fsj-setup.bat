@echo off
chcp 65001 >nul
title FSJ Second Auto Sender - Setup

rem One-file installer / updater.
rem Downloads the package, places it in its own folder and runs the wizard.
rem Running it again updates an existing install; personal settings are not
rem in the package, so they are never overwritten.
rem NOTE: keep this file ASCII-only. Japanese messages come from Python.

set "URL=https://fsjjimu.github.io/dashboard/fsj-second-sender.zip"
set "TMPZIP=%TEMP%\fsj-second-sender.zip"

rem The install folder is named in Japanese, but this file must stay ASCII
rem (Shift-JIS lead bytes collide with cmd metacharacters), so build the
rem name from character codes.
rem   30BB 30AB 30F3 30C9 = katakana SE KA N DO
rem   81EA 52D5 9001 4FE1 = kanji  JI DOU SOU SHIN
rem A plain "C:\FSJ" is not used: that folder already holds another system.
set "APP="
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; 'C:\FSJ' + [string]::Join('',[char[]](0x30BB,0x30AB,0x30F3,0x30C9,0x81EA,0x52D5,0x9001,0x4FE1))"`) do set "APP=%%p"
if "%APP%"=="" set "APP=C:\FSJ-SecondSender"

echo.
echo   FSJ Second Auto Sender
echo   ======================
echo   Install to: %APP%
echo.

rem curl and tar ship with Windows 10 (1803+) and Windows 11.
where curl >nul 2>&1
if errorlevel 1 goto :NOTOOL
where tar >nul 2>&1
if errorlevel 1 goto :NOTOOL

rem A running client keeps python312.dll open and extraction would fail
rem halfway, leaving a broken install. Stop before touching anything.
tasklist /fi "imagename eq python.exe" 2>nul | find /i "python.exe" >nul
if not errorlevel 1 (
    echo   [!] Python is running.
    echo       Close the "FSJ Second Auto Sender" window first,
    echo       then run this file again.
    echo.
    pause
    exit /b 1
)

echo   [1/3] Downloading...
curl -L -f -s -S -o "%TMPZIP%" "%URL%"
if errorlevel 1 goto :DLFAIL
if not exist "%TMPZIP%" goto :DLFAIL

echo   [2/3] Extracting...
if not exist "%APP%" mkdir "%APP%"
tar -xf "%TMPZIP%" -C "%APP%"
if errorlevel 1 goto :EXFAIL
del "%TMPZIP%" >nul 2>&1

if not exist "%APP%\python-embed\python.exe" goto :EXFAIL
if not exist "%APP%\scripts\setup_wizard.py" goto :EXFAIL

echo   [3/3] Starting setup...
echo.
cd /d "%APP%"
"%APP%\python-embed\python.exe" -X utf8 scripts\setup_wizard.py
echo.
pause
exit /b 0

:NOTOOL
echo   [ERROR] curl or tar was not found.
echo           They ship with Windows 10 and 11.
echo           Ask the administrator for the zip file instead.
echo.
pause
exit /b 1

:DLFAIL
echo   [ERROR] Download failed.
echo           Check the network connection and try again.
echo           %URL%
echo.
pause
exit /b 1

:EXFAIL
echo   [ERROR] Extraction failed.
echo           Close any open window using the folder and try again.
echo           %APP%
echo.
pause
exit /b 1
