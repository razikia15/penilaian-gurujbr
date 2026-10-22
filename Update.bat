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
echo   [1] Otomatis (Deteksi Git)
echo   [2] Manual (Ketik Changelog)
echo   [3] Keluar
echo   [4] PERBAIKI GIT (Jika macet/error terus)
echo.
set /p pilihan="Pilih mode [1/2/3/4]: "

if "%pilihan%"=="1" goto :MODE_GIT
if "%pilihan%"=="2" goto :MODE_MANUAL
if "%pilihan%"=="3" exit /b 0
if "%pilihan%"=="4" goto :FIX_GIT
goto :MENU

:: ============================================================
:: MODE 4 — PERBAIKI GIT (Abort Merge/Rebase & Reset)
:: ============================================================
:FIX_GIT
cls
echo ==========================================================
echo    MEMPERBAIKI STATUS GIT
echo ==========================================================
echo [INFO] Membatalkan proses merge/rebase yang menggantung...
git merge --abort >nul 2>&1
git rebase --abort >nul 2>&1
git reset --hard HEAD >nul 2>&1

echo [INFO] Menarik data terbaru (paksa) dari GitHub...
git fetch origin %BRANCH%
git reset --hard origin/%BRANCH%

echo.
echo ==========================================================
echo    SELESAI! Git sudah bersih dan sinkron dengan GitHub.
echo    Silakan jalankan script ini lagi dan pilih [1].
echo ==========================================================
pause & goto :MENU

:: ============================================================
:: MODE 1 — DETEKSI GIT
:: ============================================================
:MODE_GIT
:: Cek konflik
findstr /M /C:"<<<<<<<" *.html *.js *.bat >nul 2>&1
if !errorlevel! equ 0 (
    echo [ERROR] Ada file yang bentrok (tanda ^<<<<^<). Selesaikan dulu atau pilih menu [4].
    pause & goto :MENU
)

echo [INFO] Staging perubahan...
git add . >nul 2>&1

git diff --cached --quiet HEAD
if !errorlevel!==0 (
    echo [INFO] Tidak ada perubahan file yang perlu diupload.
    pause & goto :MENU
)

set "CHANGED_FILES="
for /f "tokens=*" %%f in ('git diff --cached --name-only HEAD') do (
    set "CHANGED_FILES=!CHANGED_FILES!, %%~nxf"
)

set "CHANGELOG_MSG=Update file: !CHANGED_FILES:~2!"
set BUMP_TYPE=patch
set NEW_VER=

echo   File berubah : !CHANGED_FILES:~2!
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
git add -N . >nul 2>&1
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
:: EKSEKUSI
:: ============================================================
:EXECUTE
set "CHANGELOG_MSG=!CHANGELOG_MSG:"=!"
if "!CHANGELOG_MSG!"=="" set "CHANGELOG_MSG=Update files"

echo.
echo [1/4] Update versi...
set BUMP_RESULT=
if "!BUMP_TYPE!"=="set" (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action set -Version "!NEW_VER!" -Message "!CHANGELOG_MSG!"') do set BUMP_RESULT=%%r
) else (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action patch -Message "!CHANGELOG_MSG!"') do set BUMP_RESULT=%%r
)

if "!BUMP_RESULT!"=="" (
    echo [ERROR] GAGAL UPDATE VERSI! Pastikan version.js tidak terkunci/dibuka.
    pause & goto :MENU
)
echo       !BUMP_RESULT!

echo.
echo [2/4] Commit...
git add . >nul 2>&1
git commit -m "!CHANGELOG_MSG!"
if !errorlevel! neq 0 (
    echo [ERROR] Gagal commit.
    pause & goto :MENU
)

echo.
echo [3/4] Menarik data (Rebase)...
:: MENGGUNAKAN REBASE agar history bersih dan tidak membuat commit merge
git pull origin !BRANCH! --rebase
if !errorlevel! neq 0 (
    echo.
    echo ==========================================================
    echo    [ERROR] GAGAL PULL! Ada konflik dengan GitHub.
    echo    Silakan jalankan script ini lagi dan pilih menu [4] untuk reset.
    echo ==========================================================
    pause & goto :MENU
)

echo.
echo [4/4] Push ke GitHub...
git push origin !BRANCH!
if !errorlevel! neq 0 (
    echo [ERROR] GAGAL UPLOAD KE GITHUB!
    pause & goto :MENU
)

echo.
echo ==========================================================
echo    BERHASIL TERUPLOAD! Versi baru: !BUMP_RESULT:BUMPED:=!
echo ==========================================================
timeout /t 3 >nul
exit /b 0