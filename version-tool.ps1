# ============================================================
# version-tool.ps1
# Tool untuk baca & bump versi di version.js
# Dipanggil oleh update.bat — jangan jalankan manual
# ============================================================
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('read','patch','minor','major')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Message = "Update"
)

$ErrorActionPreference = "Stop"
$filePath = Join-Path $PSScriptRoot 'version.js'

if (-not (Test-Path $filePath)) {
    Write-Host "1.0.0"
    exit 1
}

$content = Get-Content $filePath -Raw

# Cari versi (format: version: '1.1.0')
if (-not ($content -match "version:\s*'([0-9]+\.[0-9]+(?:\.[0-9]+)?)'")) {
    Write-Host "1.0.0"
    exit 1
}

$curVer = $Matches[1]

# Mode read → hanya tampilkan versi
if ($Action -eq 'read') {
    Write-Host $curVer
    exit 0
}

# Normalisasi ke format X.Y.Z
$parts = $curVer.Split('.')
while ($parts.Length -lt 3) { $parts += '0' }
[int]$major = [int]$parts[0]
[int]$minor = [int]$parts[1]
[int]$patch = [int]$parts[2]

# Bump sesuai tipe
switch ($Action) {
    'patch' { $patch++ }
    'minor' { $minor++; $patch = 0 }
    'major' { $major++; $minor = 0; $patch = 0 }
}

$newVer = "$major.$minor.$patch"
$today = (Get-Date).ToString('yyyy-MM-dd')

# Escape single quote untuk JS
$escapedMsg = $Message -replace "'", "\'"

# --- 1. Update version field (occurrence pertama = top-level) ---
$oldVerLine = "version: '$curVer'"
$newVerLine = "version: '$newVer'"
$idx = $content.IndexOf($oldVerLine)
if ($idx -ge 0) {
    $content = $content.Substring(0, $idx) + $newVerLine + $content.Substring($idx + $oldVerLine.Length)
}

# --- 2. Update buildDate field ---
if ($content -match "buildDate:\s*'([^']+)'") {
    $oldDateLine = "buildDate: '$($Matches[1])'"
    $newDateLine = "buildDate: '$today'"
    $idx2 = $content.IndexOf($oldDateLine)
    if ($idx2 -ge 0) {
        $content = $content.Substring(0, $idx2) + $newDateLine + $content.Substring($idx2 + $oldDateLine.Length)
    }
}

# --- 3. Tambahkan changelog entry baru di atas ---
$marker = 'changelog: ['
$mIdx = $content.IndexOf($marker)
if ($mIdx -ge 0) {
    $insertPos = $mIdx + $marker.Length
    $newEntry = "`n    {`n      version: 'v$newVer',`n      date: '$today',`n      highlights: [`n        '$escapedMsg'`n      ]`n    },"
    $content = $content.Substring(0, $insertPos) + $newEntry + $content.Substring($insertPos)
}

# Simpan sebagai UTF-8 tanpa BOM
[System.IO.File]::WriteAllText($filePath, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "BUMPED:$newVer"