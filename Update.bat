@echo off
setlocal EnableDelayedExpansion
color 0A
title Auto Deploy — Jabal Rahmah
cd /d "%~dp0"

:: ============================================================
:: KONFIGURASI
:: ============================================================
set GITHUB_URL=https://github.com/razikia15/penilaian-gurujbr.git
set BRANCH=main
set TEMP_DIFF=%TEMP%\jabal_diff.txt
set TEMP_BUMP=%TEMP%\jabal_ai_bump.txt
set TEMP_CL=%TEMP%\jabal_ai_changelog.txt
set API_KEY_FILE=gemini-api-key.txt

:MENU
cls
echo ==========================================================
echo    AUTO DEPLOY — Instrumen Penilaian Jabal Rahmah
echo ==========================================================
echo.
echo   [1] Otomatis (AI Gemini - GRATIS)
echo       AI analisis diff + generate changelog otomatis
echo       + tentukan tipe bump versi (patch/minor/major).
echo.
echo   [2] Manual
echo       Anda ketik sendiri changelog dan versi baru.
echo.
echo   [3] Keluar
echo.
set /p pilihan="Pilih mode [1/2/3]: "

if "%pilihan%"=="1" goto :MODE_AI
if "%pilihan%"=="2" goto :MODE_MANUAL
if "%pilihan%"=="3" exit /b 0

echo.
echo Pilihan tidak valid.
timeout /t 1 >nul
goto :MENU

:: ============================================================
:: CEK FILE PENDUKUNG (shared)
:: ============================================================
:CHECK_FILES
if not exist version.js       ( echo [ERROR] version.js tidak ditemukan       & pause & goto :MENU )
if not exist version-tool.ps1 ( echo [ERROR] version-tool.ps1 tidak ditemukan & pause & goto :MENU )
if not exist .git (
    echo [INFO] Inisialisasi git...
    git init >nul 2>&1
    git remote add origin %GITHUB_URL% >nul 2>&1
)
exit /b 0

:: ============================================================
:: MODE 1 — AI GEMINI
:: ============================================================
:MODE_AI
call :CHECK_FILES
if not exist ai-changelog.ps1 (
    echo [ERROR] ai-changelog.ps1 tidak ditemukan
    pause & goto :MENU
)

echo.
echo ==========================================================
echo    MODE OTOMATIS — AI GEMINI
echo ==========================================================
echo.

:: --- Cek API Key ---
set GEMINI_KEY=
if exist "%API_KEY_FILE%" set /p GEMINI_KEY=<"%API_KEY_FILE%"
if not defined GEMINI_KEY if defined GEMINI_API_KEY set GEMINI_KEY=%GEMINI_API_KEY%

if not defined GEMINI_KEY (
    echo [SETUP] API key Gemini belum diset.
    echo.
    echo Dapatkan API key gratis di: https://aistudio.google.com/app/apikey
    echo.
    set /p "GEMINI_KEY=Masukkan API key Gemini (diawali AIza...): "
    if "!GEMINI_KEY!"=="" (
        echo [ERROR] API key kosong.
        pause & goto :MENU
    )
    > "%API_KEY_FILE%" echo !GEMINI_KEY!
    echo [OK] API key disimpan ke %API_KEY_FILE%
    echo.
)

:: --- Baca versi saat ini ---
set CUR_VER=
for /f "delims=" %%v in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action read 2^>nul') do set CUR_VER=%%v
if "!CUR_VER!"=="" set CUR_VER=1.0.0
echo [INFO] Versi saat ini: v!CUR_VER!

:: --- Staging & cek perubahan ---
echo [INFO] Staging perubahan...
git add . >nul 2>&1

git diff --cached --quiet HEAD
if !errorlevel!==0 (
    echo.
    echo [INFO] Tidak ada perubahan file.
    echo        Edit dulu file ^(index.html / guru.html / admin.html^).
    pause & goto :MENU
)

:: --- Ambil diff ---
echo [INFO] Mengambil diff...
git diff --cached HEAD > "%TEMP_DIFF%" 2>nul
for %%A in ("%TEMP_DIFF%") do set DIFF_SIZE=%%~zA
echo [INFO] Ukuran diff: !DIFF_SIZE! bytes

:: --- Panggil AI ---
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "ai-changelog.ps1" -DiffFile "%TEMP_DIFF%" -CurrentVersion "!CUR_VER!" -ApiKey "!GEMINI_KEY!" -OutBump "%TEMP_BUMP%" -OutChangelog "%TEMP_CL%"

if !errorlevel! neq 0 (
    echo.
    echo [ERROR] AI gagal merespons. Coba lagi atau pilih mode Manual.
    git reset >nul 2>&1
    pause & goto :MENU
)

:: --- Baca hasil AI ---
set "AI_BUMP="
set "AI_CHANGELOG="
if exist "%TEMP_BUMP%" for /f "usebackq delims=" %%x in ("%TEMP_BUMP%") do set "AI_BUMP=%%x"
if exist "%TEMP_CL%"    for /f "usebackq delims=" %%x in ("%TEMP_CL%")    do set "AI_CHANGELOG=%%x"

if "!AI_BUMP!"=="" (
    echo [ERROR] AI tidak mengembalikan tipe bump.
    git reset >nul 2>&1
    pause & goto :MENU
)

:: --- Preview ---
echo.
echo ----------------------------------------------------------
echo   HASIL ANALISIS AI (GEMINI)
echo ----------------------------------------------------------
echo   Versi saat ini : v!CUR_VER!
echo   Tipe bump      : !AI_BUMP!
echo   Changelog      :
type "%TEMP_CL%"
echo ----------------------------------------------------------
echo.

set /p konfirm="Lanjutkan commit ^& push? [Y/n]: "
if /i "!konfirm!"=="n" (
    git reset >nul 2>&1
    echo.
    echo [DIBATALKAN]
    pause & goto :MENU
)

set BUMP_TYPE=!AI_BUMP!
set NEW_VER=
set "CHANGELOG_MSG=!AI_CHANGELOG!"
goto :EXECUTE

:: ============================================================
:: MODE 2 — MANUAL
:: ============================================================
:MODE_MANUAL
call :CHECK_FILES

echo.
echo ==========================================================
echo    MODE MANUAL
echo ==========================================================
echo.

:: --- Baca versi saat ini ---
set CUR_VER=
for /f "delims=" %%v in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action read 2^>nul') do set CUR_VER=%%v
if "!CUR_VER!"=="" set CUR_VER=1.0.0
echo [INFO] Versi saat ini: v!CUR_VER!
echo.

:: --- Cek ada perubahan ---
git add -N . >nul 2>&1
git diff --quiet HEAD
if !errorlevel!==0 (
    echo [INFO] Tidak ada perubahan file.
    pause & goto :MENU
)

:: --- Input changelog ---
echo Ketik changelog. Bisa beberapa poin, pisahkan dengan  ^|  .
echo Contoh: Fix bug login ^| Tambah filter kelas
echo.
set /p "USER_CL=Changelog: "
if "!USER_CL!"=="" (
    echo [ERROR] Changelog tidak boleh kosong.
    pause & goto :MENU
)

:: --- Input versi baru ---
echo.
echo Masukkan versi baru (format X.Y.Z, contoh 1.2.0).
echo Kosongkan untuk auto-bump patch dari !CUR_VER!.
echo.
set /p "USER_VER=Versi baru [otomatis]: "

set NEW_VER=
set BUMP_TYPE=patch
if defined USER_VER (
    echo !USER_VER! | findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
    if !errorlevel! neq 0 (
        echo [ERROR] Format versi tidak valid. Harus X.Y.Z
        pause & goto :MENU
    )
    set BUMP_TYPE=set
    set NEW_VER=!USER_VER!
)

:: --- Preview ---
echo.
echo ----------------------------------------------------------
echo   RINGKASAN
echo ----------------------------------------------------------
echo   Versi saat ini : v!CUR_VER!
if defined NEW_VER (
    echo   Versi baru     : v!NEW_VER!
) else (
    echo   Versi baru     : auto-bump patch
)
echo   Changelog      : !USER_CL!
echo ----------------------------------------------------------
echo.

set /p konfirm="Lanjutkan? [Y/n]: "
if /i "!konfirm!"=="n" (
    echo.
    echo [DIBATALKAN]
    pause & goto :MENU
)

set "CHANGELOG_MSG=!USER_CL!"
goto :EXECUTE

:: ============================================================
:: EKSEKUSI (shared)
:: ============================================================
:EXECUTE
echo.
echo ----------------------------------------------------------
echo   MEMPROSES...
echo ----------------------------------------------------------
echo.

:: [1/4] Bump / set versi
echo [1/4] Update versi...
set BUMP_RESULT=
if "!BUMP_TYPE!"=="set" (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action set -Version "!NEW_VER!" -Message "!CHANGELOG_MSG!" 2^>nul') do set BUMP_RESULT=%%r
) else (
    for /f "delims=" %%r in ('powershell -NoProfile -ExecutionPolicy Bypass -File "version-tool.ps1" -Action !BUMP_TYPE! -Message "!CHANGELOG_MSG!" 2^>nul') do set BUMP_RESULT=%%r
)
echo       !BUMP_RESULT!

:: [2/4] Re-stage (version.js berubah)
echo.
echo [2/4] Staging ulang...
git add . >nul 2>&1

:: [3/4] Commit
echo.
echo [3/4] Commit...
git commit -m "!CHANGELOG_MSG!" >nul 2>&1

:: [4/4] Push
echo.
echo [4/4] Push ke GitHub...
git branch -M !BRANCH! >nul 2>&1
git push -u origin !BRANCH!
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Push gagal! Cek koneksi atau login GitHub.
    pause & exit /b 1
)

:: --- Bersihkan temp ---
del "%TEMP_DIFF%" "%TEMP_BUMP%" "%TEMP_CL%" >nul 2>&1

echo.
echo ==========================================================
echo    SELESAI!
echo ==========================================================
if not "!BUMP_RESULT!"=="" (
    echo    Versi baru  : !BUMP_RESULT:BUMPED:=!
)
echo    Changelog   : !CHANGELOG_MSG!
echo    Netlify     : https://app.netlify.com
echo    Website     : https://penilaian-gurujbr.netlify.app
echo ==========================================================
echo.
echo Tunggu 1-2 menit, lalu refresh browser.
echo.

pause
endlocal
exit /b 0