@echo off
setlocal EnableDelayedExpansion
color 0A
title Auto Deploy — Jabal Rahmah
cd /d "%~dp0"

set GITHUB_URL=https://github.com/razikia15/penilaian-gurujbr.git
set BRANCH=main

:MENU
cls
echo ==========================================================
echo    AUTO DEPLOY — Instrumen Penilaian Jabal Rahmah
echo ==========================================================
echo.
echo   [1] Otomatis (Deteksi Git - Tanpa AI)
echo       Membaca file apa saja yang berubah.
echo.
echo   [2] Manual (Multi-line via Notepad)
echo       Ketik changelog multi-baris + versi manual.
echo.
echo   [3] Keluar
echo.
set /p pilihan="Pilih mode [1/2/3]: "

if "%pilihan%"=="1" goto :MODE_GIT
if "%pilihan%"=="2" goto :MODE_MANUAL
if "%pilihan%"=="3" exit /b 0
goto :MENU

:: ============================================================
:: MODE 1 — DETEKSI GIT (TANPA AI)
:: ============================================================
:MODE_GIT
echo.
echo [INFO] Staging perubahan...
git add . >nul 2>&1

git diff --cached --quiet HEAD
if !errorlevel!==0 (
    echo [INFO] Tidak ada perubahan file yang perlu diupload.
    pause & goto :MENU
)

echo [INFO] Mendeteksi file yang berubah...
set "CHANGED_FILES="
for /f "tokens=*" %%f in ('git diff --cached --name-only HEAD') do (
    set "CHANGED_FILES=!CHANGED_FILES!, %%~nxf"
)

set "CHANGELOG_MSG=Update file: !CHANGED_FILES:~2!"
set BUMP_TYPE=patch
set NEW_VER=
set USE_MESSAGE_FILE=

echo.
echo ----------------------------------------------------------
echo   RINGKASAN DETEKSI
echo ----------------------------------------------------------
echo   File berubah : !CHANGED_FILES:~2!
echo   Changelog    : !CHANGELOG_MSG!
echo   Tipe bump    : patch (otomatis)
echo ----------------------------------------------------------
echo.

set /p konfirm="Lanjutkan? [Y/n]: "
if /i "!konfirm!"=="n" (
    git reset >nul 2>&1
    pause & goto :MENU
)
goto :EXECUTE

:: ============================================================
:: MODE 2 — MANUAL (MULTI-LINE VIA NOTEPAD)
:: ============================================================
:MODE_MANUAL
echo.
echo [INFO] Menyiapkan file changelog untuk diedit di Notepad...
set "TEMP_CHANGELOG=%TEMP%\jbr_changelog_%RANDOM%.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Content -LiteralPath $env:TEMP_CHANGELOG -Encoding UTF8 -Value @('# ============================================================','# FORMAT CHANGELOG','# ============================================================','# - Baris kosong diabaikan','# - Baris mulai dengan ## = HEADER (otomatis ditebalkan)','# - Baris mulai dengan # tunggal = komentar (diabaikan)','# - Baris lain = bullet biasa','# - Emoji dan simbol didukung (UTF-8)','# ============================================================','# CONTOH:','#   ## Login','#   Login bisa pakai email atau username','#   Smart Mode cek database dulu','#   ## Admin','#   Tab Cetak Rapor ATS dan Semester','# ============================================================','','## ',''); Start-Process notepad.exe -ArgumentList $env:TEMP_CHANGELOG -Wait"

if not exist "!TEMP_CHANGELOG!" (
    echo [ERROR] File changelog tidak ditemukan. Dibatalkan.
    pause & goto :MENU
)

echo.
echo [INFO] File changelog tersimpan.
set USE_MESSAGE_FILE=1

set /p "USER_VER=Versi baru (X.Y.Z) [kosongkan untuk auto-patch]: "

set BUMP_TYPE=patch
set NEW_VER=
if defined USER_VER (
    set BUMP_TYPE=set
    set NEW_VER=!USER_VER!
)
goto :EXECUTE

:: ============================================================
:: EKSEKUSI (SHARED)
:: ============================================================
:EXECUTE
echo.
echo ----------------------------------------------------------
echo   [1/4] Update versi version.js...
echo ----------------------------------------------------------
set BUMP_RESULT=

if "!USE_MESSAGE_FILE!"=="1" (
    if "!BUMP_TYPE!"=="set" (
        for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action set -Version "!NEW_VER!" -MessageFile "!TEMP_CHANGELOG!"') do set BUMP_RESULT=%%r
    ) else (
        for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action patch -MessageFile "!TEMP_CHANGELOG!"') do set BUMP_RESULT=%%r
    )
) else (
    if "!BUMP_TYPE!"=="set" (
        for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action set -Version "!NEW_VER!" -Message "!CHANGELOG_MSG!"') do set BUMP_RESULT=%%r
    ) else (
        for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action patch -Message "!CHANGELOG_MSG!"') do set BUMP_RESULT=%%r
    )
)

if "!BUMP_RESULT!"=="" (
    echo.
    echo [ERROR] GAGAL UPDATE VERSI!
    echo Pastikan file version.js TIDAK SEDANG DIBUKA di Notepad/VS Code.
    if exist "!TEMP_CHANGELOG!" del "!TEMP_CHANGELOG!" >nul 2>&1
    pause & goto :MENU
)
echo       !BUMP_RESULT!
set "NEW_VERSION=!BUMP_RESULT:BUMPED:=!"

REM Tentukan commit message default
if "!USE_MESSAGE_FILE!"=="1" (
    set "COMMIT_MSG=Update v!NEW_VERSION!"
) else (
    set "COMMIT_MSG=!CHANGELOG_MSG!"
)
set /p "OVERRIDE_MSG=Commit message [kosongkan = !COMMIT_MSG!]: "
if defined OVERRIDE_MSG set "COMMIT_MSG=!OVERRIDE_MSG!"

echo.
echo ----------------------------------------------------------
echo   [2/4] Commit...
echo ----------------------------------------------------------
git add . >nul 2>&1
git commit -m "!COMMIT_MSG!"
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Gagal melakukan commit.
    if exist "!TEMP_CHANGELOG!" del "!TEMP_CHANGELOG!" >nul 2>&1
    pause & goto :MENU
)

echo.
echo ----------------------------------------------------------
echo   [3/4] Menarik data terbaru dari GitHub...
echo ----------------------------------------------------------
git pull origin !BRANCH! --no-rebase --no-edit
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Gagal Pull. Kemungkinan ada bentrok file di GitHub.
    if exist "!TEMP_CHANGELOG!" del "!TEMP_CHANGELOG!" >nul 2>&1
    pause & goto :MENU
)

echo.
echo ----------------------------------------------------------
echo   [4/4] Push ke GitHub...
echo ----------------------------------------------------------
git push -u origin !BRANCH!
if !errorlevel! neq 0 (
    echo.
    echo ==========================================================
    echo    [ERROR] GAGAL UPLOAD KE GITHUB!
    echo    Periksa koneksi internet atau login GitHub Anda.
    echo ==========================================================
    if exist "!TEMP_CHANGELOG!" del "!TEMP_CHANGELOG!" >nul 2>&1
    pause & goto :MENU
)

if exist "!TEMP_CHANGELOG!" del "!TEMP_CHANGELOG!" >nul 2>&1

echo.
echo ==========================================================
echo    BERHASIL TERUPLOAD! Versi baru: !NEW_VERSION!
echo ==========================================================
pause
goto :MENU