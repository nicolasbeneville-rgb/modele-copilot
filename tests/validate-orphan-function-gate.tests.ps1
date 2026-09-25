[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gatePath = Join-Path $PSScriptRoot '..\.github\validate-orphan-function-gate.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('orphan-function-gate-' + [Guid]::NewGuid().ToString('N'))

function Write-Fixture {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$Content
    )

    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $Directory 'fixture.js'), $Content, (New-Object Text.UTF8Encoding($false)))
}

function Invoke-Gate {
    param(
        [Parameter(Mandatory = $true)][string]$FixturePath,
        [Parameter(Mandatory = $true)][string]$FunctionName,
        [Parameter(Mandatory = $true)][string[]]$EntryPoints,
        [switch]$ExpectJson
    )

    $arguments = @('-Path', $FixturePath, '-FunctionName', $FunctionName, '-EntryPoint') + $EntryPoints
    if ($ExpectJson) {
        $arguments += '-Json'
    }
    $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gatePath @arguments 2>&1 | ForEach-Object { $_.ToString() })
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output -join "`n")
    }
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

try {
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

    $reachablePath = Join-Path $testRoot 'reachable'
    Write-Fixture -Directory $reachablePath -Content @'
function main() {
    used();
}

function used() {
    return 1;
}
'@
    $reachableResult = Invoke-Gate -FixturePath $reachablePath -FunctionName 'used' -EntryPoints @('main')
    Assert-True ($reachableResult.ExitCode -eq 0) ('reachable fixture failed: ' + $reachableResult.Output)
    Assert-True ($reachableResult.Output -match 'CALL CHAIN') ('call chain missing from PASS evidence: ' + $reachableResult.Output)
    Assert-True ($reachableResult.Output -match 'fixture.js:1') ('entry point location missing from PASS evidence: ' + $reachableResult.Output)
    Assert-True ($reachableResult.Output -match 'fixture.js:2') ('call site location missing from PASS evidence: ' + $reachableResult.Output)

    $orphanPath = Join-Path $testRoot 'orphan'
    Write-Fixture -Directory $orphanPath -Content @'
function main() {
    used();
}

function used() {
    return 1;
}

function orphan() {
    return 2;
}
'@
    $orphanResult = Invoke-Gate -FixturePath $orphanPath -FunctionName 'orphan' -EntryPoints @('main')
    Assert-True ($orphanResult.ExitCode -eq 1) ('orphan fixture did not fail: ' + $orphanResult.Output)
    Assert-True ($orphanResult.Output -match 'orphan') ('orphan name missing from evidence: ' + $orphanResult.Output)
    Assert-True ($orphanResult.Output -match 'SCANNED ENTRY POINTS: main') ('scanned entry points missing from FAIL evidence: ' + $orphanResult.Output)

    $uncertainPath = Join-Path $testRoot 'uncertain'
    Write-Fixture -Directory $uncertainPath -Content @'
function main() {
    window[key]();
}

function target() {
    return 1;
}
'@
    $uncertainResult = Invoke-Gate -FixturePath $uncertainPath -FunctionName 'target' -EntryPoints @('main')
    Assert-True ($uncertainResult.ExitCode -eq 2) ('dynamic fixture did not become uncertain: ' + $uncertainResult.Output)
    Assert-True ($uncertainResult.Output -match 'UNCERTAINTY') ('uncertainty missing from evidence: ' + $uncertainResult.Output)

    $missingEntryPath = Join-Path $testRoot 'missing-entry'
    Write-Fixture -Directory $missingEntryPath -Content @'
function main() {
    return 1;
}
'@
    $missingEntryResult = Invoke-Gate -FixturePath $missingEntryPath -FunctionName 'main' -EntryPoints @('doGet')
    Assert-True ($missingEntryResult.ExitCode -eq 2) ('missing entry point did not fail as input error: ' + $missingEntryResult.Output)

    Write-Output 'ORPHAN-FUNCTION-GATE TESTS PASS (4 cases: PASS chain, FAIL scanned roots, UNCERTAIN dynamic, invalid root)'
    exit 0
} catch {
    Write-Output ('ORPHAN-FUNCTION-GATE TESTS FAIL: ' + $_.Exception.Message)
    exit 1
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
    }
}