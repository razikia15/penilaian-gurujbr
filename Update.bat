@echo off
color 0A
title Auto Deploy ke Netlify

echo ========================================================
echo      SCRIPT UPDATE OTOMATIS (GITHUB -^> NETLIFY)
echo ========================================================
echo.

:: Cek apakah folder ini adalah git repository
if not exist .git (
    echo [PERINGATAN] Folder ini belum di-setup sebagai Git repository.
    echo Menginisialisasi Git...
    git init
    git remote add origin https://github.com/razikia15/penilaian-gurujbr.git
    echo Git berhasil diinisialisasi.
    echo.
)

echo Pilih file yang baru saja Anda edit:
echo [1] index.html
echo [2] guru.html
echo [3] admin.html
echo [4] Update keseluruhan / Lainnya
echo.
set /p pilihan="Masukkan angka pilihan (1/2/3/4): "

if "%pilihan%"=="1" set pesan=Update index.html
if "%pilihan%"=="2" set pesan=Update guru.html
if "%pilihan%"=="3" set pesan=Update admin.html
if "%pilihan%"=="4" set pesan=Update project files
if not defined pesan set pesan=Update website

echo.
echo [1/4] Menyiapkan file...
git add .

echo.
echo [2/4] Menyimpan perubahan ke Git...
git commit -m "%pesan%"

echo.
echo [3/4] Memastikan nama branch utama adalah 'main'...
git branch -M main

echo.
echo [4/4] Mengirim ke GitHub...
git push -u origin main

echo.
echo ========================================================
echo   PROSES SELESAI! Netlify sedang mengupdate website Anda.
echo ========================================================
pause