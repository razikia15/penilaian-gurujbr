@echo off
setlocal EnableDelayedExpansion
color 0A
title Auto Deploy — Detect Changes + Bump Version
cd /d "%~dp0"

:: ============================================================
:: KONFIGURASI
:: ============================================================
set GITHUB_URL=https://github.com/razikia15/penilaian-gurujbr.git
set BRANCH=main

:: Default bump type (dapat di-override via argumen)
set BUMP_TYPE=patch
if /i "%~1"=="minor" set BUMP_TYPE=minor
if /i "%~1"=="major" set BUMP_TYPE=major
if /i "%~1"=="skip"  set BUMP_TYPE=none

cls
echo ==========================================================
echo    AUTO UPDATE — Detect Changes + Bump Version
echo ==========================================================
echo    Bump type: %BUMP_TYPE%
echo ==========================================================
echo.

:: ============================================================
:: CEK GIT REPO
:: ============================================================
if not exist .git (
    echo [INFO] Menginisialisasi Git...
    git init >nul 2>&1
    git remote add origin %GITHUB_URL% >nul 2>&1
    echo [OK]  Git siap.
    echo.
)

:: ============================================================
:: CEK FILE PENDUKUNG
:: ============================================================
if not exist version.js (
    echo [ERROR] File "version.js" tidak ditemukan!
    pause & exit /b 1
)
if not exist version-tool.ps1 (
    echo [ERROR] File "version-tool.ps1" tidak ditemukan!
    pause & exit /b 1
)

:: ============================================================
:: DETEKSI FILE YANG BERUBAH
:: ============================================================
set "CHANGED_FILES="
set /a FILE_COUNT=0

for /f "tokens=2* delims=	 " %%a in ('git status --porcelain 2^>nul') do (
    set "file=%%a"
    set "file=!file: =!"
    set /a FILE_COUNT+=1
    if !FILE_COUNT! LEQ 3 (
        if defined CHANGED_FILES (
            set "CHANGED_FILES=!CHANGED_FILES!, !file!"
        ) else (
            set "CHANGED_FILES=!file!"
        )
    )
)

if %FILE_COUNT%==0 (
    echo.
    echo [INFO] Tidak ada perubahan file.
    echo        Edit dulu file-nya ^(index.html / guru.html / admin.html^).
    echo.
    pause & exit /b 0
)

:: ============================================================
:: GENERATE CHANGELOG MESSAGE OTOMATIS
:: ============================================================
if %FILE_COUNT% GTR 3 (
    set "CHANGELOG_MSG=Update project files ^(%FILE_COUNT% files^)"
) else (
    set "CHANGELOG_MSG=Update: !CHANGED_FILES!"
)

:: ============================================================
:: BACA VERSI SAAT INI
:: ============================================================
for /f "delims=" %%v in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action read 2^>nul') do set CUR_VER=%%v
if "!CUR_VER!"=="" set CUR_VER=1.0.0

:: ============================================================
:: PREVIEW
:: ============================================================
echo File yang berubah ^(%FILE_COUNT% file^):
git status --short
echo.
echo ----------------------------------------------------------
echo   RINGKASAN UPDATE
echo ----------------------------------------------------------
echo   Versi saat ini : v!CUR_VER!
if not "!BUMP_TYPE!"=="none" (
    echo   Bump type      : !BUMP_TYPE!
) else (
    echo   Bump type      : (skip)
)
echo   Changelog      : !CHANGELOG_MSG!
echo   Branch         : !BRANCH!
echo ----------------------------------------------------------
echo.

:: ============================================================
:: KONFIRMASI (Enter = lanjut)
:: ============================================================
set /p konfirm="Lanjutkan? [Y/n] (Enter = Y): "
if /i "!konfirm!"=="n" (
    echo.
    echo [DIBATALKAN]
    pause & exit /b 0
)

:: ============================================================
:: EKSEKUSI
:: ============================================================
echo.
echo ----------------------------------------------------------
echo   MEMPROSES...
echo ----------------------------------------------------------
echo.

:: [1/5] Bump versi
if not "!BUMP_TYPE!"=="none" (
    echo [1/5] Bump versi ^(!BUMP_TYPE!^)...
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action !BUMP_TYPE! -Message "!CHANGELOG_MSG!" 2^>nul') do set BUMP_RESULT=%%r
    echo       !BUMP_RESULT!
) else (
    echo [1/5] Skip bump versi.
)

:: [2/5] Staging
echo.
echo [2/5] Staging file...
git add . >nul 2>&1

:: [3/5] Commit
echo.
echo [3/5] Commit...
git commit -m "!CHANGELOG_MSG!" >nul 2>&1

:: [4/5] Branch
echo.
echo [4/5] Branch: !BRANCH!
git branch -M !BRANCH! >nul 2>&1

:: [5/5] Push
echo.
echo [5/5] Push ke GitHub...
git push -u origin !BRANCH!
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Push gagal! Cek koneksi atau login GitHub.
    pause & exit /b 1
)

:: ============================================================
:: SELESAI
:: ============================================================
echo.
echo ==========================================================
echo    ✅ SELESAI!
echo ==========================================================
if not "!BUMP_TYPE!"=="none" (
    echo    Versi baru  : v!BUMP_RESULT:BUMPED:=!
)
echo    Changelog   : !CHANGELOG_MSG!
echo    Netlify     : https://app.netlify.com
echo    Website     : https://penilaian-gurujbr.netlify.app
echo ==========================================================
echo.
echo 💡 Tunggu 1-2 menit, lalu refresh browser Anda.
echo.

pause
endlocal