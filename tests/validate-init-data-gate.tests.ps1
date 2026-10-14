[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gatePath = Join-Path $PSScriptRoot '..\.github\validate-init-data-gate.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('init-data-gate-' + [Guid]::NewGuid().ToString('N'))

function Write-Fixture {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][hashtable]$Files
    )

    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    $encoding = New-Object System.Text.UTF8Encoding($false)
    foreach ($file in $Files.GetEnumerator()) {
        $filePath = Join-Path $Directory $file.Key
        $parentPath = Split-Path -Parent $filePath
        if (-not (Test-Path -LiteralPath $parentPath)) {
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
        }
        [IO.File]::WriteAllText($filePath, [string]$file.Value, $encoding)
    }
}

function Invoke-Gate {
    param([Parameter(Mandatory = $true)][string]$FixturePath)

    $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gatePath -Path $FixturePath 2>&1)
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output | ForEach-Object { $_.ToString() }) -join "`n"
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

    $s1Path = Join-Path $testRoot 'S1'
    Write-Fixture -Directory $s1Path -Files @{ 'fixture.js' = "ss.getSheetByName('Clients') || ss.insertSheet('Clients');" }
    $s1 = Invoke-Gate -FixturePath $s1Path
    Assert-True -Condition ($s1.ExitCode -eq 0) -Message ('S1 expected exit 0: ' + $s1.Output)
    Assert-True -Condition ($s1.Output.Contains('PROOF: Clients read fixture.js:1 <- init fixture.js:1')) -Message ('S1 proof missing: ' + $s1.Output)

    $s2Path = Join-Path $testRoot 'S2'
    Write-Fixture -Directory $s2Path -Files @{ 'fixture.js' = "ss.getSheetByName('Orders');" }
    $s2 = Invoke-Gate -FixturePath $s2Path
    Assert-True -Condition ($s2.ExitCode -eq 1) -Message ('S2 expected exit 1: ' + $s2.Output)
    Assert-True -Condition ($s2.Output.Contains('MISSING-INIT: sheet Orders fixture.js:1')) -Message ('S2 missing-init evidence absent: ' + $s2.Output)

    $s3Path = Join-Path $testRoot 'S3'
    Write-Fixture -Directory $s3Path -Files @{
        'initialize.js' = "properties.setProperty('API_URL', value);"
        'reader.js' = "properties.getProperty('API_URL');"
    }
    $s3 = Invoke-Gate -FixturePath $s3Path
    Assert-True -Condition ($s3.ExitCode -eq 0) -Message ('S3 expected exit 0: ' + $s3.Output)
    Assert-True -Condition ($s3.Output.Contains('PROOF: API_URL read reader.js:1 <- init initialize.js:1')) -Message ('S3 cross-file proof missing: ' + $s3.Output)

    $s4Path = Join-Path $testRoot 'S4'
    Write-Fixture -Directory $s4Path -Files @{ 'fixture.js' = "properties.getProperty('TOKEN');" }
    $s4 = Invoke-Gate -FixturePath $s4Path
    Assert-True -Condition ($s4.ExitCode -eq 1) -Message ('S4 expected exit 1: ' + $s4.Output)
    Assert-True -Condition ($s4.Output.Contains('MISSING-INIT: property TOKEN fixture.js:1')) -Message ('S4 missing-init evidence absent: ' + $s4.Output)

    $s5Path = Join-Path $testRoot 'S5'
    Write-Fixture -Directory $s5Path -Files @{ 'fixture.js' = "properties.getProperty('MODE') || 'prod';" }
    $s5 = Invoke-Gate -FixturePath $s5Path
    Assert-True -Condition ($s5.ExitCode -eq 0) -Message ('S5 expected exit 0: ' + $s5.Output)

    $s6Path = Join-Path $testRoot 'S6'
    Write-Fixture -Directory $s6Path -Files @{ 'fixture.js' = 'ss.getSheetByName(name);' }
    $s6 = Invoke-Gate -FixturePath $s6Path
    Assert-True -Condition ($s6.ExitCode -eq 2) -Message ('S6 expected exit 2: ' + $s6.Output)
    Assert-True -Condition ($s6.Output.Contains('UNCERTAINTY: fixture.js:1')) -Message ('S6 uncertainty evidence absent: ' + $s6.Output)

    $s7Path = Join-Path $testRoot 'S7'
    Write-Fixture -Directory $s7Path -Files @{
        'missing.js' = "ss.getSheetByName('Orders');"
        'dynamic.js' = 'ss.getSheetByName(name);'
    }
    $s7 = Invoke-Gate -FixturePath $s7Path
    Assert-True -Condition ($s7.ExitCode -eq 1) -Message ('S7 expected FAIL priority exit 1: ' + $s7.Output)
    Assert-True -Condition ($s7.Output.Contains('MISSING-INIT: sheet Orders')) -Message ('S7 missing-init absent: ' + $s7.Output)
    Assert-True -Condition ($s7.Output.Contains('UNCERTAINTY: dynamic.js:1')) -Message ('S7 uncertainty absent: ' + $s7.Output)

    $s8Path = Join-Path $testRoot 'S8'
    Write-Fixture -Directory $s8Path -Files @{ 'fixture.js' = "// ss.getSheetByName('X');`n/* ss.getSheetByName('Y'); */" }
    $s8 = Invoke-Gate -FixturePath $s8Path
    Assert-True -Condition ($s8.ExitCode -eq 0) -Message ('S8 expected exit 0: ' + $s8.Output)
    Assert-True -Condition ($s8.Output.Contains('Files: 1 | Reads: 0 | Inits: 0')) -Message ('S8 comment calls were scanned: ' + $s8.Output)

    $s9 = Invoke-Gate -FixturePath (Join-Path $testRoot 'does-not-exist')
    Assert-True -Condition ($s9.ExitCode -eq 2) -Message ('S9 expected exit 2: ' + $s9.Output)
    Assert-True -Condition ($s9.Output.Contains('INIT-DATA-GATE ERROR:')) -Message ('S9 input error output absent: ' + $s9.Output)

    $s10Path = Join-Path $testRoot 'S10'
    Write-Fixture -Directory $s10Path -Files @{ 'fixture.js' = "properties.setProperties({A:'1','B':'2'});`nproperties.getProperty('A');`nproperties.getProperty('B');" }
    $s10 = Invoke-Gate -FixturePath $s10Path
    Assert-True -Condition ($s10.ExitCode -eq 0) -Message ('S10 expected exit 0: ' + $s10.Output)
    Assert-True -Condition ($s10.Output.Contains('PROOF: A read fixture.js:2 <- init fixture.js:1')) -Message ('S10 proof for A missing: ' + $s10.Output)
    Assert-True -Condition ($s10.Output.Contains('PROOF: B read fixture.js:3 <- init fixture.js:1')) -Message ('S10 proof for B missing: ' + $s10.Output)

    $s11Path = Join-Path $testRoot 'S11'
    Write-Fixture -Directory $s11Path -Files @{ 'fixture.js' = 'properties.setProperties();' }
    $s11 = Invoke-Gate -FixturePath $s11Path
    Assert-True -Condition ($s11.ExitCode -eq 2) -Message ('S11 expected exit 2: ' + $s11.Output)
    Assert-True -Condition ($s11.Output.Contains('INIT-DATA-GATE UNCERTAIN')) -Message ('S11 expected UNCERTAIN: ' + $s11.Output)
    Assert-True -Condition ($s11.Output.Contains('UNCERTAINTY: fixture.js:1 setProperties() argument is not a literal object.')) -Message ('S11 uncertainty absent: ' + $s11.Output)

    $s12Path = Join-Path $testRoot 'S12'
    Write-Fixture -Directory $s12Path -Files @{ 'empty.js' = ''; 'fixture.js' = "ss.getSheetByName('Orders');" }
    $s12 = Invoke-Gate -FixturePath $s12Path
    Assert-True -Condition ($s12.ExitCode -eq 1) -Message ('S12 expected exit 1: ' + $s12.Output)
    Assert-True -Condition ($s12.Output.Contains('Files: 2 | Reads: 1 | Inits: 0')) -Message ('S12 counts wrong: ' + $s12.Output)
    Assert-True -Condition ($s12.Output.Contains('MISSING-INIT: sheet Orders fixture.js:1')) -Message ('S12 missing-init absent: ' + $s12.Output)

    $s13Path = Join-Path $testRoot 'S13'
    Write-Fixture -Directory $s13Path -Files @{ 'fixture.js' = "var x = '';`nss.getSheetByName('Orders');" }
    $s13 = Invoke-Gate -FixturePath $s13Path
    Assert-True -Condition ($s13.ExitCode -eq 1) -Message ('S13 expected exit 1: ' + $s13.Output)
    Assert-True -Condition ($s13.Output.Contains('MISSING-INIT: sheet Orders fixture.js:2')) -Message ('S13 missing-init absent: ' + $s13.Output)

    $s14Path = Join-Path $testRoot 'S14'
    Write-Fixture -Directory $s14Path -Files @{ 'fixture.js' = "ss.getSheetByName('');" }
    $s14 = Invoke-Gate -FixturePath $s14Path
    Assert-True -Condition ($s14.ExitCode -eq 1) -Message ('S14 expected exit 1: ' + $s14.Output)
    Assert-True -Condition ($s14.Output.Contains('INIT-DATA-GATE FAIL')) -Message ('S14 expected FAIL: ' + $s14.Output)

    Write-Output 'INIT-DATA-GATE TESTS PASS (14 cases: S1-S14)'
    exit 0
} catch {
    Write-Output ('INIT-DATA-GATE TESTS FAIL: ' + $_.Exception.Message)
    exit 1
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        [IO.Directory]::Delete($testRoot, $true)
    }
}