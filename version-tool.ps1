<#
============================================================
  VERSION TOOL — Pengelola Versi version.js
============================================================
  Usage:
    version-tool.ps1 -Action read
    version-tool.ps1 -Action patch -Message "Bullet 1 | Bullet 2"
    version-tool.ps1 -Action patch -MessageFile "changelog.txt"
    version-tool.ps1 -Action set -Version "1.3.0" -MessageFile "changelog.txt"

  Format file changelog (.txt):
    ## 🔐 Login            ← HEADER (otomatis <b>bold</b>)
    📧 Login bisa email    ← bullet biasa
    # komentar diabaikan   ← komentar (single #)
    (baris kosong)         ← diabaikan
============================================================
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('read','patch','minor','major','set')]
    [string]$Action,

    [string]$Message = 'Update aplikasi',
    [string]$MessageFile = '',
    [string]$Version = ''
)

$ErrorActionPreference = 'Stop'

$versionFile = Join-Path $PSScriptRoot 'version.js'

if (-not (Test-Path $versionFile)) {
    Write-Error "File version.js tidak ditemukan di: $PSScriptRoot"
    exit 1
}

$content = Get-Content $versionFile -Raw -Encoding UTF8
$versionMatch = [regex]::Match($content, "version:\s*['""]([0-9]+\.[0-9]+\.[0-9]+)['""]")
if (-not $versionMatch.Success) {
    Write-Error "Format 'version' tidak valid di version.js"
    exit 1
}
$currentVersion = $versionMatch.Groups[1].Value

if ($Action -eq 'read') {
    Write-Output $currentVersion
    exit 0
}

# ===== HITUNG VERSI BARU =====
$parts = $currentVersion -split '\.'
$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2]

if ($Action -eq 'set') {
    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        Write-Error "Format versi tidak valid: '$Version'. Harus X.Y.Z"
        exit 1
    }
    $newVersion = $Version
} else {
    switch ($Action) {
        'patch' { $patch = $patch + 1 }
        'minor' { $minor = $minor + 1; $patch = 0 }
        'major' { $major = $major + 1; $minor = 0; $patch = 0 }
    }
    $newVersion = "$major.$minor.$patch"
}

$today = Get-Date -Format 'yyyy-MM-dd'

# ===== ESCAPE UNTUK JS + HTML =====
function ConvertTo-JsSafe {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $t = $Text.Trim()
    $t = $t -replace '\\', '\\'        # backslash → JS escape
    $t = $t -replace "'", "\'"         # kutip tunggal → JS escape
    $t = $t -replace '&', '&amp;'      # & → HTML entity
    $t = $t -replace '<', '&lt;'       # < → HTML entity
    $t = $t -replace '>', '&gt;'       # > → HTML entity
    $t = $t -replace '`r?`n', ' '      # newline → spasi
    return $t
}

# ===== KUMPULKAN BULLETS =====
$rawBullets = @()

if ($MessageFile -and (Test-Path -LiteralPath $MessageFile)) {
    # MODE FILE — baca baris demi baris
    $lines = Get-Content -LiteralPath $MessageFile -Encoding UTF8
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t -eq '') { continue }

        # Header: "## ..."  → akan di-bold
        if ($t -match '^##\s+(.*)$') {
            $hdr = $matches[1].Trim()
            if ($hdr -ne '') { $rawBullets += "<b>$hdr</b>" }
            continue
        }
        # Komentar: "# ..." (single hash)
        if ($t -match '^#') { continue }

        # Bullet biasa
        $rawBullets += $t
    }
} else {
    # MODE PIPA (backward compat) — pisah dengan |
    $rawBullets = $Message -split '\s*\|\s*'
}

# ===== ESCAPE CONTENT (header tetap dengan tag <b>) =====
$cleanBullets = @()
foreach ($b in $rawBullets) {
    if (-not $b -or $b.Trim() -eq '') { continue }
    $t = $b.Trim()

    if ($t -match '^<b>(.*)</b>$') {
        # Header — escape isi, pertahankan tag <b>
        $inner = $matches[1]
        $safeInner = ConvertTo-JsSafe $inner
        if ($safeInner -ne '') { $cleanBullets += "<b>$safeInner</b>" }
    } else {
        $cleanBullets += ConvertTo-JsSafe $t
    }
}

if ($cleanBullets.Count -eq 0) {
    $cleanBullets = @('Update aplikasi')
}

# ===== BANGUN ENTRY JS =====
$bulletsJs = ($cleanBullets | ForEach-Object { "        '$_'" }) -join ",`r`n"

$newEntry = @"
    {
      version: 'v$newVersion',
      date: '$today',
      highlights: [
$bulletsJs
      ]
    },
"@

# ===== SISIPKAN KE version.js =====
$pattern = "(changelog\s*:\s*\[\s*\r?\n)"
if ($content -match $pattern) {
    $content = $content -replace $pattern, "`$1$newEntry`r`n"
} else {
    Write-Error "Tidak bisa menemukan array 'changelog' di version.js"
    exit 1
}

$content = $content -replace "version:\s*['""][0-9]+\.[0-9]+\.[0-9]+['""]", "version: '$newVersion'"
$content = $content -replace "buildDate:\s*['""][^'""]+['""]", "buildDate: '$today'"

Set-Content -Path $versionFile -Value $content -Encoding UTF8 -NoNewline

Write-Output "BUMPED:$newVersion"