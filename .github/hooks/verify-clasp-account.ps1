<#!
.SYNOPSIS
    Verifies active clasp identity from the project hook directory.
#>
[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$RegistryPath = ''
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $PSCommandPath
$workspaceRoot = $scriptRoot
while ($workspaceRoot -and -not (Test-Path (Join-Path $workspaceRoot '_governance'))) {
    $parent = Split-Path -Parent $workspaceRoot
    if ($parent -eq $workspaceRoot) { $workspaceRoot = '' } else { $workspaceRoot = $parent }
}

function Stop-Check([string]$Message, [int]$Code = 1) {
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    exit $Code
}

if (-not $RegistryPath) {
    if (-not $workspaceRoot) { Stop-Check 'Unable to locate a parent _governance directory.' 2 }
    $RegistryPath = Join-Path $workspaceRoot '_governance\clasp-project-registry.md'
}

$projectRoot = (Resolve-Path -Path $ProjectPath -ErrorAction Stop).Path
$projectName = Split-Path -Leaf $projectRoot
if (-not (Test-Path (Join-Path $projectRoot '.clasp.json'))) {
    Stop-Check "No .clasp.json in $projectRoot; this is not a clasp project."
}
if (-not (Test-Path $RegistryPath)) { Stop-Check "Registry not found: $RegistryPath" 2 }

$entry = $null
foreach ($line in Get-Content -Path $RegistryPath -Encoding UTF8) {
    if ($line -match '^\|\s*' + [regex]::Escape($projectName) + '\s*\|') {
        $parts = $line.Split('|') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        if ($parts.Count -ge 2) { $entry = $parts[1] }
        break
    }
}
if (-not $entry -or $entry -notmatch '^\s*(PRO|PERSO)\s+-\s+([^|]+)\s*$') {
    Stop-Check "Registry entry for '$projectName' has no exact account identity." 2
}
$accountType = $Matches[1]
$expectedIdentity = $Matches[2].Trim()

Push-Location $projectRoot
try {
    $raw = & clasp show-authorized-user --json 2>&1
    if ($LASTEXITCODE -ne 0) { Stop-Check "clasp identity command failed: $($raw -join ' ')" }
    $identity = ($raw -join "`n") | ConvertFrom-Json
} finally { Pop-Location }

$activeEmail = [string]$identity.email
if ([string]::IsNullOrWhiteSpace($activeEmail) -or $activeEmail.Trim().ToLowerInvariant() -ne $expectedIdentity.ToLowerInvariant()) {
    Stop-Check "Active clasp identity '$activeEmail' does not match '$expectedIdentity'."
}
Write-Host "[OK] $projectName -> $accountType -> $activeEmail" -ForegroundColor Green
exit 0
