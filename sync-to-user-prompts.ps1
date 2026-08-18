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
    "bug-analysis"
    "copywriting"
    "design-audit"
    "design-harmony"
    "doc-sync"
    "prompt-engineering"
    "seo"
    "completion-check"
)

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}

$copied = 0
foreach ($skill in $generics) {
    $srcPath = Join-Path $source "$skill.md"
    $dstPath = Join-Path $dest "$skill.prompt.md"
    if (Test-Path $srcPath) {
        if ($DryRun) {
            Write-Host "[DRY] Would copy: $skill" -ForegroundColor Cyan
        } else {
            if (Test-Path $dstPath) {
                Remove-Item -Path $dstPath -Force
            }
            Copy-Item -Path $srcPath -Destination $dstPath -Force
            Write-Host "[OK] $skill" -ForegroundColor Green
            $copied++
        }
    } else {
        Write-Host "[SKIP] Not found in source: $skill" -ForegroundColor Yellow
    }
}

Write-Host "`nDone. $copied skills synced to: $dest" -ForegroundColor White
exit 0
