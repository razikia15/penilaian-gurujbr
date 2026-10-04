@echo off
setlocal EnableDelayedExpansion
color 0A
title Auto Deploy + Version Bump ke Netlify
cd /d "%~dp0"

:: ============================================================
:: KONFIGURASI (ubah jika perlu)
:: ============================================================
set GITHUB_URL=https://github.com/razikia15/penilaian-gurujbr.git
set BRANCH=main

:: ============================================================
:: HEADER
:: ============================================================
cls
echo ==========================================================
echo    SCRIPT UPDATE OTOMATIS
echo    GitHub -^> Netlify  +  Auto Version Bump
echo ==========================================================
echo.

:: ============================================================
:: CEK GIT REPO
:: ============================================================
if not exist .git (
    echo [INFO] Folder belum jadi Git repository.
    echo        Menginisialisasi...
    git init >nul 2>&1
    git remote add origin %GITHUB_URL% >nul 2>&1
    echo [OK]  Git siap digunakan.
    echo.
)

:: ============================================================
:: CEK FILE PENDUKUNG
:: ============================================================
if not exist version.js (
    echo [ERROR] File "version.js" tidak ditemukan!
    echo         Buat file version.js terlebih dahulu.
    echo.
    pause
    exit /b 1
)
if not exist version-tool.ps1 (
    echo [ERROR] File "version-tool.ps1" tidak ditemukan!
    echo         Buat file version-tool.ps1 terlebih dahulu.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: BACA VERSI SAAT INI
:: ============================================================
for /f "delims=" %%v in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action read 2^>nul') do set CUR_VER=%%v
if "!CUR_VER!"=="" set CUR_VER=1.0.0

echo Versi saat ini: v!CUR_VER!
echo.

:: ============================================================
:: PILIH JENIS UPDATE
:: ============================================================
echo ==========================================================
echo    PILIH JENIS UPDATE
echo ==========================================================
echo    [1] Bug fix kecil      (patch)   v!CUR_VER! -^> vX.Y.Z+1
echo    [2] Fitur baru         (minor)   v!CUR_VER! -^> vX.Y+1.0
echo    [3] Update besar       (major)   v!CUR_VER! -^> vX+1.0.0
echo    [4] Skip bump versi    (commit ^& push saja)
echo.
set /p jenis="Pilihan [1-4] (Enter = patch): "

if "!jenis!"=="" set jenis=1
set BUMP_TYPE=patch
if "!jenis!"=="2" set BUMP_TYPE=minor
if "!jenis!"=="3" set BUMP_TYPE=major
if "!jenis!"=="4" set BUMP_TYPE=none

:: ============================================================
:: PILIH FILE YANG DIEDIT
:: ============================================================
echo.
echo ==========================================================
echo    FILE YANG BARU DIEDIT
echo ==========================================================
echo    [1] index.html
echo    [2] guru.html
echo    [3] admin.html
echo    [4] Semua / lainnya
echo.
set /p pilihan="Pilihan [1-4] (Enter = semua): "

set pesan=Update project files
if "!pilihan!"=="1" set pesan=Update index.html
if "!pilihan!"=="2" set pesan=Update guru.html
if "!pilihan!"=="3" set pesan=Update admin.html

:: ============================================================
:: INPUT CHANGELOG
:: ============================================================
set CHANGELOG_MSG=!pesan!
if not "!BUMP_TYPE!"=="none" (
    echo.
    echo ==========================================================
    echo    RINGKASAN UPDATE (untuk changelog)
    echo ==========================================================
    echo    Tekan Enter untuk pakai default: "!pesan!"
    set /p CHANGELOG_MSG="   Pesan: "
    if "!CHANGELOG_MSG!"=="" set CHANGELOG_MSG=!pesan!
)

:: ============================================================
:: KONFIRMASI
:: ============================================================
echo.
echo ==========================================================
echo    KONFIRMASI
echo ==========================================================
echo    Versi saat ini  : v!CUR_VER!
if not "!BUMP_TYPE!"=="none" (
    echo    Bump type       : !BUMP_TYPE!
)
echo    File            : !pesan!
echo    Changelog       : !CHANGELOG_MSG!
echo    Branch          : !BRANCH!
echo.
set /p konfirm="Lanjutkan? [Y/n] (Enter = Y): "
if /i "!konfirm!"=="n" (
    echo.
    echo [DIBATALKAN] Update tidak dijalankan.
    pause
    exit /b 0
)

:: ============================================================
:: EKSEKUSI
:: ============================================================
echo.
echo ----------------------------------------------------------
echo   MULAI PROSES
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
git add .

:: Cek ada perubahan?
git diff --cached --quiet >nul 2>&1
if !errorlevel!==0 (
    echo.
    echo [INFO] Tidak ada perubahan untuk di-commit.
    echo        Mungkin file belum disimpan, atau sudah ter-push sebelumnya.
    echo.
    pause
    exit /b 0
)

:: [3/5] Commit
echo.
echo [3/5] Commit...
git commit -m "!pesan!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [WARNING] Commit gagal atau tidak ada perubahan signifikan.
)

:: [4/5] Pastikan branch
echo.
echo [4/5] Set branch ke '!BRANCH!'...
git branch -M !BRANCH! >nul 2>&1

:: [5/5] Push
echo.
echo [5/5] Push ke GitHub...
git push -u origin !BRANCH!
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Push gagal!
    echo         Cek koneksi internet, atau login GitHub Anda.
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: SELESAI
:: ============================================================
echo.
echo ==========================================================
echo    ✅ SELESAI!
echo ==========================================================
if not "!BUMP_TYPE!"=="none" (
    echo    Versi baru      : v!BUMP_RESULT:BUMPED:=!
)
echo    Netlify sedang meng-update website Anda.
echo    Monitor deploy  : https://app.netlify.com
echo    Website         : https://penilaian-gurujbr.netlify.app
echo ==========================================================
echo.

:: ============================================================
:: INFO UNTUK USER
:: ============================================================
echo 💡 Tunggu 1-2 menit, lalu refresh browser Anda.
echo    Badge versi di pojok akan otomatis berubah.
echo.

pause
endlocal