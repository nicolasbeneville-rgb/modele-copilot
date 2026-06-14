<#
.SYNOPSIS
    Synchronise la couche .github canonique du repo modele-copilot vers les projets du workspace.

.DESCRIPTION
    Ce script remplace proprement les assets mutualises suivants dans chaque projet cible :
    - .github/copilot-instructions.md
    - .github/agents/
    - .github/skills/
    - .github/prompts/ui-ux-pro-max/

    Il ignore volontairement les prompts specifiques projet comme ml-code-review.prompt.md.
    Il peut aussi relancer la sync des user prompts VS Code en fin d'execution.

.USAGE
    .\sync-workspace-github.ps1
    .\sync-workspace-github.ps1 -DryRun
    .\sync-workspace-github.ps1 -Projects Webapp_Digitools,Webapp_Harmonisation
    .\sync-workspace-github.ps1 -SkipInstructions
    .\sync-workspace-github.ps1 -SyncUserPrompts
#>
param(
    [string[]]$Projects,
    [switch]$DryRun,
    [switch]$SkipInstructions,
    [switch]$SkipAgents,
    [switch]$SkipSkills,
    [switch]$SkipPrompts,
    [switch]$SyncUserPrompts
)

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$modelRoot = $PSScriptRoot
$modelGithubRoot = Join-Path $modelRoot '.github'

$canonicalPromptFolders = @(
    'ui-ux-pro-max'
)

function Write-Step {
    param(
        [string]$Message,
        [string]$Color = 'Cyan'
    )

    Write-Host $Message -ForegroundColor $Color
}

function Sync-File {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        Write-Step "[SKIP] Missing source file: $Source" 'Yellow'
        return
    }

    if ($DryRun) {
        Write-Step "[DRY] File  $Destination"
        return
    }

    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Copy-Item -Path $Source -Destination $Destination -Force
    Write-Step "[OK]  File  $Destination" 'Green'
}

function Sync-Directory {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        Write-Step "[SKIP] Missing source directory: $Source" 'Yellow'
        return
    }

    if ($DryRun) {
        Write-Step "[DRY] Dir   $Destination"
        return
    }

    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $Destination) {
        Remove-Item -Path $Destination -Recurse -Force
    }

    Copy-Item -Path $Source -Destination $parent -Recurse -Force
    Write-Step "[OK]  Dir   $Destination" 'Green'
}

function Get-TargetProjects {
    $allProjects = Get-ChildItem -Path $workspaceRoot -Directory |
        Where-Object { $_.Name -ne 'modele-copilot' -and -not $_.Name.StartsWith('_') } |
        Sort-Object Name

    if ($Projects -and $Projects.Count -gt 0) {
        return $allProjects | Where-Object { $Projects -contains $_.Name }
    }

    return $allProjects
}

$targets = Get-TargetProjects

if (-not $targets -or $targets.Count -eq 0) {
    throw 'No target projects found for synchronization.'
}

Write-Step "Workspace root: $workspaceRoot" 'White'
Write-Step "Targets: $($targets.Name -join ', ')" 'White'

foreach ($project in $targets) {
    $projectGithubRoot = Join-Path $project.FullName '.github'

    if ($DryRun) {
        Write-Step "`n[DRY] Project $($project.Name)" 'Magenta'
    } else {
        Write-Step "`n[SYNC] Project $($project.Name)" 'Magenta'
    }

    if (-not $SkipInstructions) {
        Sync-File -Source (Join-Path $modelGithubRoot 'copilot-instructions.md') -Destination (Join-Path $projectGithubRoot 'copilot-instructions.md')
    }

    if (-not $SkipAgents) {
        Sync-Directory -Source (Join-Path $modelGithubRoot 'agents') -Destination (Join-Path $projectGithubRoot 'agents')
    }

    if (-not $SkipSkills) {
        Sync-Directory -Source (Join-Path $modelGithubRoot 'skills') -Destination (Join-Path $projectGithubRoot 'skills')
    }

    if (-not $SkipPrompts) {
        foreach ($promptFolder in $canonicalPromptFolders) {
            Sync-Directory -Source (Join-Path $modelGithubRoot "prompts\$promptFolder") -Destination (Join-Path $projectGithubRoot "prompts\$promptFolder")
        }
    }
}

if ($SyncUserPrompts) {
    $userPromptScript = Join-Path $modelRoot 'sync-to-user-prompts.ps1'
    if ($DryRun) {
        Write-Step "`n[DRY] Would run user prompt sync: $userPromptScript"
    } elseif (Test-Path $userPromptScript) {
        Write-Step "`n[SYNC] User prompts" 'Magenta'
        & $userPromptScript
    } else {
        Write-Step "`n[SKIP] User prompt sync script not found: $userPromptScript" 'Yellow'
    }
}

Write-Step "`nDone." 'White'