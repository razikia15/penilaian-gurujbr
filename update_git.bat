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
    echo [INFO] Tidak ada perubahan file.
    pause & goto :MENU
)

echo [INFO] Mendeteksi file yang berubah...
:: Mengambil daftar file yang berubah (hanya nama filenya)
set "CHANGED_FILES="
for /f "tokens=*" %%f in ('git diff --cached --name-only HEAD') do (
    set "CHANGED_FILES=!CHANGED_FILES!, %%~nxf"
)

:: Membuat changelog otomatis berdasarkan file
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

set /p "CHANGELOG_MSG=Changelog (pisahkan dengan ^| ): "
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
echo.
echo [1/3] Update versi...
set BUMP_RESULT=
if "!BUMP_TYPE!"=="set" (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action set -Version "!NEW_VER!" -Message "!CHANGELOG_MSG!" 2^>nul') do set BUMP_RESULT=%%r
) else (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action patch -Message "!CHANGELOG_MSG!" 2^>nul') do set BUMP_RESULT=%%r
)

echo [2/3] Commit...
git add . >nul 2>&1
git commit -m "!CHANGELOG_MSG!" >nul 2>&1

echo [3/3] Push ke GitHub...
git branch -M !BRANCH! >nul 2>&1
git push -u origin !BRANCH!

echo.
echo ==========================================================
echo    SELESAI! Versi baru: !BUMP_RESULT:BUMPED:=!
echo ==========================================================
pause