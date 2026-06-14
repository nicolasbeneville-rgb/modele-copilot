<#
.SYNOPSIS
    Synchronise les skills génériques depuis modele-copilot vers les User prompts VS Code.
    Après exécution, tous les workspaces VS Code bénéficient des skills mis à jour.

.USAGE
    .\sync-to-user-prompts.ps1
    .\sync-to-user-prompts.ps1 -DryRun   # Affiche sans copier
#>
param(
    [switch]$DryRun
)

$source = Join-Path $PSScriptRoot ".github\skills"
$dest = Join-Path $env:APPDATA "Code\User\prompts"

# Skills génériques à synchroniser (ne pas inclure les skills spécifiques projet)
$generics = @(
    "copilot-expert-costar"
    "api-decision"
    "backup-checkpoint"
    "bug-analysis"
    "copywriting"
    "design-audit"
    "design-harmony"
    "doc-sync"
    "prompt-engineering"
    "security-review"
    "seo"
    "verification-before-completion"
)

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$copied = 0
foreach ($skill in $generics) {
    $srcPath = Join-Path $source $skill
    $dstPath = Join-Path $dest $skill
    if (Test-Path $srcPath) {
        if ($DryRun) {
            Write-Host "[DRY] Would copy: $skill" -ForegroundColor Cyan
        } else {
            if (Test-Path $dstPath) {
                Remove-Item -Path $dstPath -Recurse -Force
            }
            Copy-Item -Path $srcPath -Destination $dest -Recurse -Force
            Write-Host "[OK] $skill" -ForegroundColor Green
            $copied++
        }
    } else {
        Write-Host "[SKIP] Not found in source: $skill" -ForegroundColor Yellow
    }
}

Write-Host "`nDone. $copied skills synced to: $dest" -ForegroundColor White
