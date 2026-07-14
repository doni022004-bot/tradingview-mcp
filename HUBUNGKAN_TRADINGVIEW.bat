@echo off
setlocal
chcp 65001 >nul
cls
echo ============================================
echo   MENYAMBUNGKAN KE TRADINGVIEW DESKTOP
echo ============================================
echo.
echo Jangan tutup jendela ini sampai selesai.
echo.

cd /d "%~dp0"

if not exist "scripts\launch_tv_debug.bat" (
    echo [GAGAL] File scripts\launch_tv_debug.bat tidak ditemukan.
    echo Pastikan file .bat ini berada di folder utama tradingview-mcp
    echo ^(folder yang sama dengan package.json^).
    echo.
    pause
    exit /b 1
)

if not exist "node_modules" (
    echo [1/2] Menginstall dependensi npm, mohon tunggu...
    call npm install
    if errorlevel 1 (
        echo.
        echo [GAGAL] npm install gagal.
        echo Pastikan Node.js sudah terpasang: https://nodejs.org
        echo.
        pause
        exit /b 1
    )
    echo.
)

echo [2/2] Membuka TradingView Desktop dengan mode debug aktif...
echo.
call scripts\launch_tv_debug.bat
set LAUNCH_RESULT=%errorlevel%

echo.
echo ============================================
if %LAUNCH_RESULT% neq 0 (
    echo   GAGAL TERSAMBUNG
    echo   Silakan baca pesan error di atas layar ini.
    echo   Penyebab paling umum:
    echo    - TradingView Desktop belum terpasang
    echo    - Instalasi MSIX diblokir ^(gunakan tool tv_launch di Claude Code^)
) else (
    echo   BERHASIL! TradingView sudah siap dipakai.
    echo.
    echo   Langkah selanjutnya:
    echo    1. Buka Claude Code di komputer ini
    echo    2. Jalankan tool "tv_health_check"
    echo    3. Pastikan hasilnya "cdp_connected": true
)
echo ============================================
echo.
pause
