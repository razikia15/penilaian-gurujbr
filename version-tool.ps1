<#
============================================================
  VERSION TOOL — Pengelola Versi version.js
============================================================
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('read','patch','minor','major','set')]
    [string]$Action,

    [string]$Message = 'Update aplikasi',
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
}
else {
    switch ($Action) {
        'patch' { $patch = $patch + 1 }
        'minor' { $minor = $minor + 1; $patch = 0 }
        'major' { $major = $major + 1; $minor = 0; $patch = 0 }
    }
    $newVersion = "$major.$minor.$patch"
}

$today = Get-Date -Format 'yyyy-MM-dd'

function ConvertTo-JsSafe {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $t = $Text.Trim()
    $t = $t -replace '\\', '\\'
    $t = $t -replace "'",  "\'"
    $t = $t -replace '`r?`n', ' '
    return $t
}

$rawBullets = $Message -split '\s*\|\s*'
$cleanBullets = @()
foreach ($b in $rawBullets) {
    if ($b -and $b.Trim() -ne '') {
        $cleanBullets += (ConvertTo-JsSafe $b)
    }
}
if ($cleanBullets.Count -eq 0) { $cleanBullets = @('Update aplikasi') }

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