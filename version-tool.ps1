<#
.SYNOPSIS
    Version Tool — Baca & Bump versi otomatis di version.js
.DESCRIPTION
    Dipanggil oleh update.bat untuk:
    - read  : baca versi saat ini
    - patch : 1.0.0 → 1.0.1
    - minor : 1.0.1 → 1.1.0
    - major : 1.1.0 → 2.0.0
.EXAMPLE
    powershell -File version-tool.ps1 -Action read
    powershell -File version-tool.ps1 -Action patch -Message "Fix login bug"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('read','patch','minor','major')]
    [string]$Action,

    [string]$Message = 'Update aplikasi'
)

$ErrorActionPreference = 'Stop'

# --- Lokasi file version.js (satu folder dengan skrip ini) ---
$versionFile = Join-Path $PSScriptRoot 'version.js'

if (-not (Test-Path $versionFile)) {
    Write-Error "File version.js tidak ditemukan di: $PSScriptRoot"
    exit 1
}

$content = Get-Content $versionFile -Raw -Encoding UTF8

# --- Baca versi saat ini ---
$versionMatch = [regex]::Match($content, "version:\s*['""]([0-9]+\.[0-9]+\.[0-9]+)['""]")
if (-not $versionMatch.Success) {
    Write-Error "Format version tidak valid di version.js"
    exit 1
}
$currentVersion = $versionMatch.Groups[1].Value

# --- Mode READ: cukup kembalikan versi ---
if ($Action -eq 'read') {
    Write-Output $currentVersion
    exit 0
}

# --- Parse versi ---
$parts = $currentVersion -split '\.'
$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2]

# --- Bump sesuai tipe ---
switch ($Action) {
    'patch' { $patch++ }
    'minor' { $minor++; $patch = 0 }
    'major' { $major++; $minor = 0; $patch = 0 }
}

$newVersion = "$major.$minor.$patch"
$today      = Get-Date -Format 'yyyy-MM-dd'

# --- Escape karakter khusus untuk JS string ---
$safeMsg = $Message -replace '\\', '\\' -replace "'", "\'" -replace '`r?`n', ' '

# --- Buat entry changelog baru ---
$newEntry = @"
    {
      version: 'v$newVersion',
      date: '$today',
      highlights: [
        '$safeMsg'
      ]
    },
"@

# --- Sisipkan entry baru di awal array changelog ---
$pattern = "(changelog\s*:\s*\[\s*\r?\n)"
if ($content -match $pattern) {
    $content = $content -replace $pattern, "`$1$newEntry`r`n"
} else {
    Write-Error "Tidak bisa menemukan array 'changelog' di version.js"
    exit 1
}

# --- Update field version & buildDate ---
$content = $content -replace "version:\s*['""][0-9]+\.[0-9]+\.[0-9]+['""]", "version: '$newVersion'"
$content = $content -replace "buildDate:\s*['""][^'""]+['""]", "buildDate: '$today'"

# --- Tulis kembali ---
Set-Content -Path $versionFile -Value $content -Encoding UTF8 -NoNewline

# --- Kembalikan versi baru ke update.bat ---
Write-Output "BUMPED:$newVersion"