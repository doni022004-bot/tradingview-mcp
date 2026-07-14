@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cls
echo ================================================
echo   OTOMATIS: UNDUH + PASANG + SAMBUNGKAN
echo   KE TRADINGVIEW
echo ================================================
echo.
echo Jangan tutup jendela ini. Proses berjalan otomatis,
echo cukup tunggu sampai selesai.
echo.

set "INSTALL_DIR=%USERPROFILE%\tradingview-mcp"
set "CONFIG_DIR=%APPDATA%\Claude"
set "CONFIG_FILE=%CONFIG_DIR%\claude_desktop_config.json"

REM ---------- Step 1: Node.js ----------
where node >nul 2>&1
if errorlevel 1 (
    echo [1/5] Node.js belum terpasang. Mencoba pasang otomatis via winget...
    where winget >nul 2>&1
    if errorlevel 1 (
        echo.
        echo [GAGAL] winget tidak tersedia di komputer ini ^(Windows terlalu lama^).
        echo Silakan install Node.js manual dari https://nodejs.org lalu jalankan file ini lagi.
        echo.
        pause
        exit /b 1
    )
    winget install -e --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo [GAGAL] Instalasi Node.js otomatis gagal.
        echo Install manual dari https://nodejs.org lalu jalankan file ini lagi.
        echo.
        pause
        exit /b 1
    )
    echo Node.js terpasang. Menyegarkan PATH untuk sesi ini...
    if exist "%ProgramFiles%\nodejs\node.exe" set "PATH=%PATH%;%ProgramFiles%\nodejs"
    if exist "%ProgramFiles(x86)%\nodejs\node.exe" set "PATH=%PATH%;%ProgramFiles(x86)%\nodejs"
    if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" set "PATH=%PATH%;%LOCALAPPDATA%\Programs\nodejs"
    where node >nul 2>&1
    if errorlevel 1 (
        echo.
        echo [GAGAL] Node.js terpasang tapi tidak ditemukan di lokasi umum.
        echo Tutup jendela ini, buka Command Prompt baru, lalu jalankan file ini lagi.
        echo.
        pause
        exit /b 1
    )
    echo.
) else (
    echo [1/5] Node.js sudah terpasang.
)

REM ---------- Step 2: download + extract project ----------
if exist "%INSTALL_DIR%\package.json" (
    echo [2/5] Folder proyek sudah ada di %INSTALL_DIR%
) else (
    echo [2/5] Mengunduh proyek tradingview-mcp ke %INSTALL_DIR% ...
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/tradesdontlie/tradingview-mcp/archive/refs/heads/main.zip' -OutFile '%TEMP%\tvmcp.zip'; Expand-Archive -Path '%TEMP%\tvmcp.zip' -DestinationPath '%TEMP%\tvmcp_extract' -Force; Move-Item -Path '%TEMP%\tvmcp_extract\tradingview-mcp-main' -Destination '%INSTALL_DIR%' -Force"
    if not exist "%INSTALL_DIR%\package.json" (
        echo.
        echo [GAGAL] Unduh/ekstrak proyek gagal. Periksa koneksi internet Anda.
        echo.
        pause
        exit /b 1
    )
    echo.
)

cd /d "%INSTALL_DIR%"

REM ---------- Step 3: npm install ----------
if exist "node_modules" (
    echo [3/5] Dependensi sudah terpasang.
) else (
    echo [3/5] Memasang dependensi ^(npm install^), mohon tunggu...
    call npm install
    if errorlevel 1 (
        echo.
        echo [GAGAL] npm install gagal.
        echo.
        pause
        exit /b 1
    )
    echo.
)

REM ---------- Step 4: launch TradingView with CDP ----------
echo [4/5] Membuka TradingView Desktop dengan mode debug aktif...
echo.
call scripts\launch_tv_debug.bat
set LAUNCH_RESULT=%errorlevel%
echo.

REM ---------- Step 5: Claude Desktop config ----------
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
set "ARGS_PATH=%INSTALL_DIR%\src\server.js"
set "ARGS_PATH=!ARGS_PATH:\=\\!"

if exist "%CONFIG_FILE%" (
    echo [5/5] File config Claude Desktop sudah ada di:
    echo   %CONFIG_FILE%
    echo Saya tidak menimpanya otomatis supaya server MCP lain Anda ^(kalau ada^) tidak hilang.
    echo Tambahkan blok berikut secara manual ke dalam "mcpServers":
    echo.
    echo   "tradingview": { "command": "node", "args": ["!ARGS_PATH!"] }
    echo.
) else (
    echo [5/5] Membuat file config Claude Desktop baru...
    (
        echo {
        echo   "mcpServers": {
        echo     "tradingview": {
        echo       "command": "node",
        echo       "args": ["!ARGS_PATH!"]
        echo     }
        echo   }
        echo }
    ) > "%CONFIG_FILE%"
    echo Dibuat di: %CONFIG_FILE%
)

echo.
echo ================================================
if %LAUNCH_RESULT% neq 0 (
    echo   TRADINGVIEW GAGAL TERSAMBUNG
    echo   Baca pesan error di atas layar ini.
) else (
    echo   BERHASIL! TradingView siap dipakai.
    echo   Folder proyek: %INSTALL_DIR%
    echo.
    echo   Langkah terakhir ^(wajib^):
    echo    1. TUTUP Claude Desktop sepenuhnya ^(cek System Tray, klik kanan, Quit^)
    echo    2. Buka lagi Claude Desktop
    echo    3. Tanyakan ke Claude: "cek koneksi tradingview" atau jalankan tv_health_check
)
echo ================================================
echo.
pause
