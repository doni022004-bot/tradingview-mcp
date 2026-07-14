@echo off
REM Launch TradingView Desktop on Windows with Chrome DevTools Protocol enabled
REM Usage: scripts\launch_tv_debug.bat [port]

set PORT=%1
if "%PORT%"=="" set PORT=9222

REM Kill existing TradingView instances
REM (ping -n is used for waits throughout: timeout /t aborts when stdin is redirected)
taskkill /F /IM TradingView.exe >nul 2>&1
ping -n 3 127.0.0.1 >nul

REM Auto-detect TradingView install location
set "TV_EXE="

REM Check common install locations
if exist "%LOCALAPPDATA%\TradingView\TradingView.exe" set "TV_EXE=%LOCALAPPDATA%\TradingView\TradingView.exe"
if exist "%PROGRAMFILES%\TradingView\TradingView.exe" set "TV_EXE=%PROGRAMFILES%\TradingView\TradingView.exe"
if exist "%PROGRAMFILES(x86)%\TradingView\TradingView.exe" set "TV_EXE=%PROGRAMFILES(x86)%\TradingView\TradingView.exe"

REM Check MSIX / Windows Store installs.
REM Get-AppxPackage resolves the install without elevation; enumerating
REM %PROGRAMFILES%\WindowsApps with dir requires admin rights, so keep it as a fallback.
if "%TV_EXE%"=="" (
    for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "(Get-AppxPackage -Name 'TradingView.Desktop' -ErrorAction SilentlyContinue).InstallLocation" 2^>nul`) do (
        if exist "%%i\TradingView.exe" set "TV_EXE=%%i\TradingView.exe"
    )
)
if "%TV_EXE%"=="" (
    for /f "tokens=*" %%i in ('dir /s /b "%PROGRAMFILES%\WindowsApps\TradingView*\TradingView.exe" 2^>nul') do set "TV_EXE=%%i"
)
if "%TV_EXE%"=="" (
    for /f "tokens=*" %%i in ('where TradingView.exe 2^>nul') do set "TV_EXE=%%i"
)

if "%TV_EXE%"=="" (
    echo Error: TradingView not found.
    echo Checked: %%LOCALAPPDATA%%\TradingView, %%PROGRAMFILES%%\TradingView, WindowsApps
    echo.
    echo If installed elsewhere, run manually:
    echo   "C:\path\to\TradingView.exe" --remote-debugging-port=%PORT%
    exit /b 1
)

echo Found TradingView at: %TV_EXE%
echo Starting with --remote-debugging-port=%PORT%...
start "" "%TV_EXE%" --remote-debugging-port=%PORT%

echo Waiting for CDP to become available...
ping -n 6 127.0.0.1 >nul

REM Use 127.0.0.1 rather than localhost: on some machines localhost resolves to
REM IPv6 ::1, which Electron's debug server does not listen on.
set TRIES=0
:check
curl -s http://127.0.0.1:%PORT%/json/version >nul 2>&1
if %errorlevel% equ 0 goto ready
set /a TRIES+=1
if %TRIES% geq 15 goto msix_fallback
echo Still waiting...
ping -n 3 127.0.0.1 >nul
goto check

:msix_fallback
REM Some Windows MSIX builds block the debug port when launched straight out of
REM WindowsApps. Copy the package to a plain (non-ACL-restricted) folder under
REM LOCALAPPDATA and retry from there -- same fallback tv_launch uses.
echo %TV_EXE% | findstr /I "WindowsApps" >nul
if errorlevel 1 (
    echo.
    echo Error: TradingView is running but CDP never became available on port %PORT%.
    exit /b 1
)

echo.
echo CDP did not come up from WindowsApps. Retrying from a local copy...
for %%F in ("%TV_EXE%") do set "TV_SRC_DIR=%%~dpF"
if "%TV_SRC_DIR:~-1%"=="\" set "TV_SRC_DIR=%TV_SRC_DIR:~0,-1%"
for %%N in ("%TV_SRC_DIR%") do set "TV_PKG_NAME=%%~nxN"
set "TV_LOCAL_DIR=%LOCALAPPDATA%\tradingview-mcp\%TV_PKG_NAME%"
set "TV_LOCAL_EXE=%TV_LOCAL_DIR%\TradingView.exe"

if not exist "%TV_LOCAL_EXE%" (
    echo Copying package to %TV_LOCAL_DIR% ^(one-time, may take a minute^)...
    taskkill /F /IM TradingView.exe >nul 2>&1
    ping -n 3 127.0.0.1 >nul
    if not exist "%LOCALAPPDATA%\tradingview-mcp" mkdir "%LOCALAPPDATA%\tradingview-mcp"
    robocopy "%TV_SRC_DIR%" "%TV_LOCAL_DIR%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
)

if not exist "%TV_LOCAL_EXE%" (
    echo.
    echo Error: Local copy fallback failed. Use the tv_launch MCP tool instead --
    echo it has the same fallback but with more detailed diagnostics.
    exit /b 1
)

taskkill /F /IM TradingView.exe >nul 2>&1
ping -n 3 127.0.0.1 >nul
echo Starting local copy: %TV_LOCAL_EXE%
start "" "%TV_LOCAL_EXE%" --remote-debugging-port=%PORT%

set TRIES=0
:check2
ping -n 3 127.0.0.1 >nul
curl -s http://127.0.0.1:%PORT%/json/version >nul 2>&1
if %errorlevel% equ 0 goto ready
set /a TRIES+=1
if %TRIES% geq 15 (
    echo.
    echo Error: CDP still did not come up after the local-copy fallback.
    echo Use the tv_launch MCP tool for more detailed diagnostics.
    exit /b 1
)
echo Still waiting...
goto check2

:ready
echo.
echo CDP ready at http://127.0.0.1:%PORT%
curl -s http://127.0.0.1:%PORT%/json/version
echo.
