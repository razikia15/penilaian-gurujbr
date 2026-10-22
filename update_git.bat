@echo off
setlocal EnableDelayedExpansion
color 0A
title Auto Deploy — Jabal Rahmah
cd /d "%~dp0"

set GITHUB_URL=https://github.com/razikia15/penilaian-gurujbr.git
set BRANCH=main

:: --- CEK GIT INSTALL ---
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git tidak terinstall atau tidak dikenali di PATH.
    pause & exit /b 1
)

:: --- CEK KONFIGURASI GIT ---
git config user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Mengatur nama Git...
    git config --global user.name "razikia15"
    git config --global user.email "razikia15@users.noreply.github.com"
)

:MENU
cls
echo ==========================================================
echo    AUTO DEPLOY — Instrumen Penilaian Jabal Rahmah
echo ==========================================================
echo.
echo   [1] Otomatis (Deteksi Git - Tanpa AI)
echo       Membaca file apa saja yang berubah.
echo.
echo   [2] Manual
echo       Anda ketik sendiri changelog dan versi baru.
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
:: MODE 2 — MANUAL
:: ============================================================
:MODE_MANUAL
echo.
echo [INFO] Staging perubahan...
git add -N . >nul 2>&1

echo [INFO] File yang berubah:
git diff --stat HEAD
echo.

set /p "CHANGELOG_MSG=Changelog (pisahkan dengan koma): "
if "!CHANGELOG_MSG!"=="" goto :MENU

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
:: Bersihkan karakter yang bisa merusak perintah Git
set "CHANGELOG_MSG=!CHANGELOG_MSG:"=!"
if "!CHANGELOG_MSG!"=="" set "CHANGELOG_MSG=Update files"

echo.
echo ----------------------------------------------------------
echo   [1/4] Update versi...
echo ----------------------------------------------------------
set BUMP_RESULT=
if "!BUMP_TYPE!"=="set" (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action set -Version "!NEW_VER!" -Message "!CHANGELOG_MSG!"') do set BUMP_RESULT=%%r
) else (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action patch -Message "!CHANGELOG_MSG!"') do set BUMP_RESULT=%%r
)

if "!BUMP_RESULT!"=="" (
    echo.
    echo [ERROR] GAGAL UPDATE VERSI!
    echo Pastikan file version.js TIDAK SEDANG DIBUKA di editor.
    pause & goto :MENU
)
echo       !BUMP_RESULT!

echo.
echo ----------------------------------------------------------
echo   [2/4] Commit...
echo ----------------------------------------------------------
git add . >nul 2>&1
git commit -m "!CHANGELOG_MSG!"
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Gagal melakukan commit.
    pause & goto :MENU
)

echo.
echo ----------------------------------------------------------
echo   [3/4] Menarik data terbaru dari GitHub...
echo ----------------------------------------------------------
git pull origin !BRANCH! --no-rebase --no-edit
if !errorlevel! neq 0 (
    echo.
    echo ==========================================================
    echo    [ERROR] GAGAL PULL (KONFLIK)!
    echo    Kemungkinan ada file yang bentrok antara lokal dan GitHub.
    echo    Selesaikan konflik secara manual atau pastikan tidak ada
    echo    file yang sedang terbuka/dikunci.
    echo ==========================================================
    pause & goto :MENU
)

echo.
echo ----------------------------------------------------------
echo   [4/4] Push ke GitHub...
echo ----------------------------------------------------------
git push origin !BRANCH!
if !errorlevel! neq 0 (
    echo.
    echo ==========================================================
    echo    [ERROR] GAGAL UPLOAD KE GITHUB!
    echo    Periksa koneksi internet atau login GitHub Anda.
    echo ==========================================================
    pause & goto :MENU
)

echo.
echo ==========================================================
echo    BERHASIL TERUPLOAD! Versi baru: !BUMP_RESULT:BUMPED:=!
echo ==========================================================
timeout /t 3 >nul
exit /b 0