<#
.SYNOPSIS
    AI Changelog Generator — Google Gemini API (Gratis)
#>

param(
    [Parameter(Mandatory=$true)][string]$DiffFile,
    [Parameter(Mandatory=$true)][string]$CurrentVersion,
    [string]$ApiKey = '',
    [string]$OutBump = '',
    [string]$OutChangelog = ''
)

$ErrorActionPreference = 'Stop'

# Cek API Key (dari argumen, env var, atau file)
if (-not $ApiKey) { $ApiKey = $env:GEMINI_API_KEY }
if (-not $ApiKey) {
    $keyFile = Join-Path $PSScriptRoot 'gemini-api-key.txt'
    if (Test-Path $keyFile) { $ApiKey = (Get-Content $keyFile -Raw).Trim() }
}
if (-not $ApiKey) { Write-Error "API key Gemini tidak ditemukan."; exit 1 }

if (-not (Test-Path $DiffFile)) { Write-Error "Diff file tidak ditemukan: $DiffFile"; exit 1 }

# Baca Diff
$diffLines = Get-Content $DiffFile -Encoding UTF8
if ($diffLines.Count -gt 800) {
    $diff = ($diffLines[0..799] -join "`n") + "`n... (truncated karena terlalu panjang)"
} else {
    $diff = $diffLines -join "`n"
}

# Susun Prompt
$promptLines = @(
    "Anda adalah asisten analis perubahan kode (git diff) untuk aplikasi web penilaian madrasah.",
    "Tugas Anda:",
    "1. Ringkas perubahan menjadi 1-3 poin changelog BAHASA INDONESIA yang singkat, jelas, dan fokus pada dampak ke pengguna/developer.",
    '2. Tentukan tipe bump versi Semantic Versioning: "patch" (bugfix/kecil), "minor" (fitur baru), atau "major" (breaking change).',
    "",
    "Balas HANYA dengan format JSON valid tanpa markdown, tanpa penjelasan tambahan:",
    '{"changelog":["poin 1","poin 2"],"bump":"patch"}',
    "",
    "Versi saat ini: $CurrentVersion",
    "Diff:",
    "``````diff",
    $diff,
    "``````"
)
$prompt = $promptLines -join "`n"

# Susun Request untuk Gemini
$bodyObj = @{
    contents = @(
        @{ parts = @( @{ text = $prompt } ) }
    )
}
$body = $bodyObj | ConvertTo-Json -Depth 10 -Compress
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

$headers = @{
    "Content-Type" = "application/json"
}

# Endpoint Gemini API
$url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$ApiKey"

Write-Host "[AI] Menghubungi Google Gemini API..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $bodyBytes -TimeoutSec 90
} catch {
    Write-Error "Gagal menghubungi Gemini API: $_"
    exit 1
}

$content = $response.candidates[0].content.parts[0].text
if (-not $content) { Write-Error "Respons AI kosong."; exit 1 }

# Bersihkan format markdown jika AI membungkus JSON dengan ```json
$content = $content.Trim()
$content = $content -replace '^```json\s*', '' -replace '^```\s*', '' -replace '\s*```\s*$', ''

try {
    $parsed = $content | ConvertFrom-Json
} catch {
    Write-Error "Gagal parse JSON dari AI. Respons: $content"
    exit 1
}

$bump = [string]$parsed.bump
if ($bump -notin @('patch','minor','major')) {
    Write-Error "Bump type tidak valid: $bump"
    exit 1
}

$changelog = ($parsed.changelog) -join ' | '

# Simpan Hasil
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if ($OutBump)      { [System.IO.File]::WriteAllText($OutBump, $bump, $utf8NoBom) }
if ($OutChangelog) { [System.IO.File]::WriteAllText($OutChangelog, $changelog, $utf8NoBom) }

Write-Host "[AI] Selesai." -ForegroundColor Green
Write-Output "BUMP=$bump"
Write-Output "CHANGELOG=$changelog"