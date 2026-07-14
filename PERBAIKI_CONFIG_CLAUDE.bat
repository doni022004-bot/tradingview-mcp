@echo off
setlocal
chcp 65001 >nul
cls
echo ================================================
echo   MEMPERBAIKI CONFIG CLAUDE DESKTOP
echo ================================================
echo.

set "INSTALL_DIR=%USERPROFILE%\tradingview-mcp"
set "CONFIG_FILE=%APPDATA%\Claude\claude_desktop_config.json"

if not exist "%INSTALL_DIR%\src\server.js" (
    echo [GAGAL] Tidak menemukan %INSTALL_DIR%\src\server.js
    echo.
    echo Proyek tradingview-mcp belum terpasang di lokasi standar.
    echo Jalankan dulu HUBUNGKAN_TRADINGVIEW.bat, baru jalankan file ini lagi.
    echo.
    pause
    exit /b 1
)

echo Lokasi proyek terdeteksi: %INSTALL_DIR%
echo File config: %CONFIG_FILE%
echo.
echo Menulis entri "tradingview" dengan path yang benar
echo ^(server MCP lain di file ini tidak akan dihapus^)...
echo.

powershell -NoProfile -Command ^
  "$configPath = '%CONFIG_FILE%';" ^
  "$serverPath = '%INSTALL_DIR%\src\server.js';" ^
  "$dir = Split-Path $configPath;" ^
  "if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }" ^
  "if (Test-Path $configPath) { $json = Get-Content $configPath -Raw | ConvertFrom-Json } else { $json = [PSCustomObject]@{} }" ^
  "if (-not ($json.PSObject.Properties.Name -contains 'mcpServers')) { $json | Add-Member -NotePropertyName mcpServers -NotePropertyValue ([PSCustomObject]@{}) }" ^
  "$entry = [PSCustomObject]@{ command = 'node'; args = @($serverPath) };" ^
  "if ($json.mcpServers.PSObject.Properties.Name -contains 'tradingview') { $json.mcpServers.tradingview = $entry } else { $json.mcpServers | Add-Member -NotePropertyName tradingview -NotePropertyValue $entry }" ^
  "$json | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8;" ^
  "Write-Host 'OK'"

if errorlevel 1 (
    echo.
    echo [GAGAL] Terjadi kesalahan saat menulis config.
    pause
    exit /b 1
)

echo.
echo ================================================
echo   BERHASIL! Config sudah diperbaiki.
echo.
echo   Langkah terakhir ^(wajib^):
echo    1. TUTUP TOTAL Claude Desktop ^(klik kanan ikon System Tray, Quit^)
echo    2. Buka lagi Claude Desktop
echo    3. Tanyakan ke Claude: "cek koneksi tradingview"
echo ================================================
echo.
pause
