<#
.SYNOPSIS
    Synchronise la couche .github canonique du repo modele-copilot vers les projets du workspace.

.DESCRIPTION
    Ce script remplace proprement les assets mutualises suivants dans chaque projet cible :
    - .github/copilot-instructions-commun.md
    - .github/copilot-instructions-gas.md ou .github/copilot-instructions-react.md selon la signature du projet
    - .github/agents/
    - .github/skills/
    Il ne modifie jamais .github/copilot-instructions.md, qui reste le fichier LOCAL du projet.

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
    [switch]$ApplyRetirements,
    [switch]$SyncUserPrompts
)

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$modelRoot = $PSScriptRoot
$modelGithubRoot = Join-Path $modelRoot '.github'

$governanceRoot = Join-Path $workspaceRoot '_governance'
$coreGovernanceRoot = Join-Path $governanceRoot 'core'
$commonInstructionsSource = Join-Path $coreGovernanceRoot 'copilot-instructions-commun.md'
$qualityProcedureSource = Join-Path $governanceRoot 'governance-quality-procedure.md'
$overlayGasSource = Join-Path $governanceRoot 'overlay-gas\copilot-instructions-gas.md'
$overlayReactSource = Join-Path $governanceRoot 'overlay-react\copilot-instructions-react.md'
$retiredProjectSkills = @(
    'backup-checkpoint.md',
    'security-review.md',
    'verification-before-completion.md'
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

    # D1 Fix: Use UTF8 encoding for text files (markdown)
    $content = Get-Content -Path $Source -Raw -Encoding UTF8
    Set-Content -Path $Destination -Value $content -NoNewline -Encoding UTF8
    Write-Step "[OK]  File  $Destination" 'Green'
}

function Sync-FileIfMissing {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Label = ""
    )

    if (-not (Test-Path $Source)) {
        Write-Step "[SKIP] Missing source: $Source" 'Yellow'
        return
    }

    if (Test-Path $Destination) {
        if ($DryRun) {
            Write-Step "[OK]   $Label → already exists (protected)" 'Cyan'
        } else {
            Write-Step "[SKIP] $Label → already exists (protected)" 'Cyan'
        }
        return
    }

    if ($DryRun) {
        Write-Step "[DRY]  $Label → create $([System.IO.Path]::GetFileName($Destination))" 'Yellow'
        return
    }

    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    # R15: Copy with UTF8 encoding
    $content = Get-Content -Path $Source -Raw -Encoding UTF8
    Set-Content -Path $Destination -Value $content -NoNewline -Encoding UTF8
    Write-Step "[CREATE] $Label" 'Green'
}

function Get-RetroKey {
    param([string]$Value)

    $decomposed = $Value.Normalize([System.Text.NormalizationForm]::FormD)
    $plain = [regex]::Replace($decomposed, '\p{Mn}', '')
    return ([regex]::Replace($plain.ToLowerInvariant(), '[^a-z0-9]+', ' ')).Trim()
}

function Get-RetroBlocks {
    param([string[]]$Lines)

    $blocks = @()
    $section = 'Gouvernance & Scripts'
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $line = $Lines[$index]
        if ($line -match '^##\s+(.+)$') {
            $section = $Matches[1].Trim()
            continue
        }

        if ($line -match '^\s*-\s+\*\*(.+?)(?:\s*:)?\*\*\s*(?::\s*)?(.*)$') {
            $title = $Matches[1].Trim()
            $entryLines = @($line.Trim())
            $next = $index + 1
            while ($next -lt $Lines.Count) {
                $nextLine = $Lines[$next]
                if ($nextLine -match '^---\s*$' -or $nextLine -match '^##\s+' -or $nextLine -match '^\s*-\s+\*\*') {
                    break
                }
                if (-not [string]::IsNullOrWhiteSpace($nextLine)) {
                    $entryLines += $nextLine.Trim()
                }
                $next++
            }
            $blocks += [pscustomobject]@{
                Key = Get-RetroKey $title
                Title = $title
                Section = $section
                Lines = $entryLines
            }
            $index = $next - 1
        }
    }
    return $blocks
}

function Merge-RetroModelFile {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        Write-Step "[SKIP] Missing retro source: $Source" 'Yellow'
        return
    }

    if (-not (Test-Path $Destination)) {
        Sync-File -Source $Source -Destination $Destination
        return
    }

    $sourceBlocks = @(Get-RetroBlocks -Lines (Get-Content -Path $Source -Encoding UTF8))
    $destinationLines = [System.Collections.Generic.List[string]](Get-Content -Path $Destination -Encoding UTF8)
    $destinationKeys = @{}
    foreach ($block in Get-RetroBlocks -Lines $destinationLines.ToArray()) {
        $destinationKeys[$block.Key] = $true
    }

    $missingBlocks = @()
    foreach ($block in $sourceBlocks) {
        if (-not $destinationKeys.ContainsKey($block.Key)) {
            $missingBlocks += $block
            $destinationKeys[$block.Key] = $true
        }
    }

    if ($DryRun) {
        Write-Step "[DRY] Retro merge $Destination (new entries: $($missingBlocks.Count))"
        return
    }

    foreach ($sectionGroup in ($missingBlocks | Group-Object Section)) {
        $wantedSection = Get-RetroKey $sectionGroup.Name
        $sectionIndex = -1
        for ($index = 0; $index -lt $destinationLines.Count; $index++) {
            if ($destinationLines[$index] -match '^##\s+(.+)$' -and (Get-RetroKey $Matches[1]) -eq $wantedSection) {
                $sectionIndex = $index
                break
            }
        }
        if ($sectionIndex -lt 0) {
            continue
        }

        $insertIndex = $sectionIndex + 1
        while ($insertIndex -lt $destinationLines.Count -and $destinationLines[$insertIndex] -notmatch '^---\s*$' -and $destinationLines[$insertIndex] -notmatch '^##\s+') {
            $insertIndex++
        }

        $newLines = New-Object System.Collections.Generic.List[string]
        foreach ($block in $sectionGroup.Group) {
            [void]$newLines.Add('')
            foreach ($entryLine in $block.Lines) {
                [void]$newLines.Add($entryLine)
            }
        }
        $destinationLines.InsertRange($insertIndex, $newLines)
    }

    if ($missingBlocks.Count -gt 0) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($Destination, ($destinationLines -join [Environment]::NewLine), $utf8NoBom)
        Write-Step "[OK]  Retro merge $Destination (added: $($missingBlocks.Count))" 'Green'
    } else {
        Write-Step "[OK]  Retro merge $Destination (already aligned)" 'Cyan'
    }
}

function Sync-Directory {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Replace
    )

    if (-not (Test-Path $Source)) {
        Write-Step "[SKIP] Missing source directory: $Source" 'Yellow'
        return
    }

    if ($DryRun) {
        $mode = if ($Replace) { 'replace' } else { 'merge' }
        Write-Step "[DRY] Dir   $Destination ($mode)"
        return
    }

    if ($Replace -and (Test-Path $Destination)) {
        Remove-Item -Path $Destination -Recurse -Force
    }

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
    $mode = if ($Replace) { 'replace' } else { 'merge' }
    Write-Step "[OK]  Dir   $Destination ($mode)" 'Green'
}

function Sync-SkillDirectory {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$ProjectRoot
    )

    if (-not (Test-Path $Source)) {
        Write-Step "[SKIP] Missing source directory: $Source" 'Yellow'
        return
    }

    $statusFile = Join-Path $ProjectRoot 'projet-status.yaml'
    $statusContent = if (Test-Path $statusFile) { Get-Content $statusFile -Raw } else { '' }
    $vsgAlreadyPresent = (Test-Path (Join-Path $Destination 'vsg-integration\SKILL.md')) -or (Test-Path (Join-Path $Destination 'vsg-integration.md'))
    $vsgEnabled = $vsgAlreadyPresent -or ($statusContent -match '(?m)^vsg:\s*true\s*$')

    if ($DryRun) {
        Write-Step "[DRY] Skills $Destination (merge; VSG=$vsgEnabled)"
        foreach ($sourceFile in Get-ChildItem -Path $Source -File -Filter '*.md') {
            if ($sourceFile.Name -eq 'README.md') {
                continue
            }
            if ($sourceFile.Name -eq 'vsg-integration.md' -and -not $vsgEnabled) {
                Write-Step "[DRY] skip $($sourceFile.Name) (VSG opt-in required)" 'Yellow'
                continue
            }
            $skillPath = Join-Path $Destination (Join-Path $sourceFile.BaseName 'SKILL.md')
            Write-Step "[DRY] Skill $skillPath" 'Cyan'
            if ($ApplyRetirements) {
                $legacyPath = Join-Path $Destination $sourceFile.Name
                if (Test-Path $legacyPath) {
                    Write-Step "[DRY] migrate legacy $legacyPath" 'Yellow'
                }
            }
        }
        if ($ApplyRetirements) {
            foreach ($retiredSkill in $retiredProjectSkills) {
                $retiredPath = Join-Path $Destination $retiredSkill
                if (Test-Path $retiredPath) {
                    Write-Step "[DRY] retire $retiredPath" 'Yellow'
                }
            }
        }
        return
    }

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    foreach ($sourceFile in Get-ChildItem -Path $Source -File -Filter '*.md') {
        if ($sourceFile.Name -eq 'README.md') {
            Sync-File -Source $sourceFile.FullName -Destination (Join-Path $Destination $sourceFile.Name)
            continue
        }

        if ($sourceFile.Name -eq 'vsg-integration.md' -and -not $vsgEnabled) {
            Write-Step "[SKIP] $ProjectRoot -> vsg-integration.md (opt-in required)" 'Yellow'
            continue
        }

        $skillDirectory = Join-Path $Destination $sourceFile.BaseName
        $skillDestination = Join-Path $skillDirectory 'SKILL.md'
        if (-not (Test-Path $skillDirectory)) {
            New-Item -ItemType Directory -Path $skillDirectory -Force | Out-Null
        }
        Sync-File -Source $sourceFile.FullName -Destination $skillDestination

        if ($ApplyRetirements) {
            $legacyPath = Join-Path $Destination $sourceFile.Name
            if (Test-Path $legacyPath) {
                Remove-Item -Path $legacyPath -Force
                Write-Step "[MIGRATE] $legacyPath -> $skillDestination" 'Yellow'
            }
        }
    }

    if ($ApplyRetirements) {
        foreach ($retiredSkill in $retiredProjectSkills) {
            $retiredPath = Join-Path $Destination $retiredSkill
            if (Test-Path $retiredPath) {
                if ($DryRun) {
                    Write-Step "[DRY] retire $retiredPath" 'Yellow'
                } else {
                    Remove-Item -Path $retiredPath -Force
                    Write-Step "[RETIRE] $retiredPath" 'Yellow'
                }
            }
        }
    }
}

function Ensure-ProjectStatus {
    param([System.IO.DirectoryInfo]$Project)

    $source = Join-Path $governanceRoot 'projet-status-template.yaml'
    $destination = Join-Path $Project.FullName 'projet-status.yaml'
    if (-not (Test-Path $source)) {
        Write-Step "[SKIP] Missing project status template: $source" 'Yellow'
        return
    }
    if (Test-Path $destination) {
        $planFields = @(
            '  mode: plan_first',
            '  routing: "<agents and skills selected, or none>"',
            '  agents: "<agents to activate, or none>"',
            '  skills: "<skills to activate, or none>"',
            '  arbitrations: "<decisions made, or none>"',
            '  retirements: "<retired elements, or none>"',
            '  parallel_dispatch: "<none or explicitly independent scope>"',
            '  phase: discovery',
            '  vision: "<vision produit ou objectif utilisateur>"',
            '  challenge: "<hypothèses, contradictions, questions et contraintes à clarifier>"',
            '  clarification_status: open',
            '  global_plan: "<à construire après clarification : epics, stories et dépendances>"',
            '  epics: "<epics et résultats attendus>"',
            '  user_stories: "<user stories et critères d''acceptation>"',
            '  tasks: "<tâches claires, testables et vérifiables>"',
            '  test_level: targeted',
            '  test_matrix: "<chemin de matrice ou scénarios intégrés au plan>"',
            '  quality_dimensions: "fonction, UX/accessibilité, sécurité, messages, performance, tests, documentation, rollback"',
            '  foundations_version_start: "<integer captured at tranche start>"',
            '  foundations_version_at_completion: "<integer read at completion>"',
            '  foundations_version_change: "none | <traced amendment reference>"',
            '  foundations_version_confirmation: "none | confirmed:<human confirmation reference>"',
            '  live_test_required: false',
            '  live_test_procedure: "not_required | <project procedure path>"',
            '  live_test_status: "not_required | planned | executed | blocked"',
            '  live_test_evidence: "not_required | <output, capture or proof>"'
        )
        $existing = Get-Content -Path $destination -Raw -Encoding UTF8
        $missingFields = @($planFields | Where-Object {
            $fieldName = ($_ -split ':', 2)[0].Trim()
            $existing -notmatch ('(?m)^\s*' + [regex]::Escape($fieldName) + ':')
        })
        $missingFoundations = -not ($existing -match '(?m)^foundations:\s*$')
        if ($missingFields.Count -gt 0 -or $missingFoundations) {
            if ($DryRun) {
                Write-Step "[DRY] update $destination (add plan/foundations fields: $($missingFields.Count); foundation block=$missingFoundations)" 'Yellow'
            } else {
                $updated = $existing.TrimEnd() + "`r`n" + ($missingFields -join "`r`n") + "`r`n"
                if ($missingFoundations) {
                    $updated += "foundations:`r`n  version: 1`r`n  source: ""<CDC or canonical foundation source>""`r`n"
                }
                $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                [System.IO.File]::WriteAllText($destination, $updated, $utf8NoBom)
                Write-Step "[UPDATE] $destination (plan-first fields added)" 'Green'
            }
        }
        Write-Step "[KEEP] $($Project.Name) -> projet-status.yaml" 'Cyan'
        return
    }
    if ($DryRun) {
        Write-Step "[DRY] create $destination (plan template; fill before action)" 'Yellow'
        return
    }
    $content = Get-Content -Path $source -Raw -Encoding UTF8
    $content = $content -replace '<NomProjet>', $Project.Name
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($destination, $content, $utf8NoBom)
    Write-Step "[CREATE] $destination (plan template; fill before action)" 'Yellow'
}

function Remove-FileIfExists {
    param(
        [string]$Path,
        [string]$Label
    )

    if (-not (Test-Path $Path)) {
        return
    }

    if ($DryRun) {
        Write-Step "[DRY] remove $Label"
        return
    }

    Remove-Item -Path $Path -Force
    Write-Step "[OK]  Drop  $Label" 'Green'
}

function Get-ProjectOverlay {
    param(
        [string]$ProjectRoot
    )

    if (Test-Path (Join-Path $ProjectRoot '.clasp.json')) {
        return 'gas'
    }

    $packageJsonPath = Join-Path $ProjectRoot 'package.json'
    if (Test-Path $packageJsonPath) {
        try {
            $packageJson = Get-Content -Path $packageJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $dependencyNames = @()
            if ($packageJson.dependencies) {
                $dependencyNames += $packageJson.dependencies.PSObject.Properties.Name
            }
            if ($packageJson.devDependencies) {
                $dependencyNames += $packageJson.devDependencies.PSObject.Properties.Name
            }

            if ($dependencyNames -contains 'react') {
                return 'react'
            }
        } catch {
            Write-Step "[WARN] package.json illisible: $packageJsonPath" 'Yellow'
        }
    }

    return 'none'
}

function Get-TargetProjects {
    # D3: Read from clasp-project-registry.md (single source of truth)
    $registryPath = Join-Path $workspaceRoot '_governance\clasp-project-registry.md'

    if (-not (Test-Path $registryPath)) {
        Write-Step "[ERROR] Registry not found: $registryPath" 'Red'
        throw 'Registry not found'
    }

    # Parse registry: extract project names from "| Projet | ..."  table rows
    $registryContent = Get-Content $registryPath -Raw
    $projectLines = $registryContent -split "`n" | Where-Object { $_ -match '^\|\s+\w+' -and $_ -notmatch 'Projet' -and $_ -notmatch '---' }

    $registryProjects = @()
    foreach ($line in $projectLines) {
        $parts = $line -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        if ($parts.Count -gt 0) {
            $projectName = $parts[0]
            if ($projectName -and -not $projectName.StartsWith('-')) {
                $registryProjects += $projectName
            }
        }
    }

    # Get actual directories
    $allProjectDirs = Get-ChildItem -Path $workspaceRoot -Directory |
        Where-Object { $registryProjects -contains $_.Name }

    if ($Projects -and $Projects.Count -gt 0) {
        return $allProjectDirs | Where-Object { $Projects -contains $_.Name }
    }

    return $allProjectDirs
}

if (-not (Test-Path $commonInstructionsSource)) {
    throw "Common instructions source not found: $commonInstructionsSource"
}
if (-not (Test-Path $qualityProcedureSource)) {
    throw "Governance quality procedure not found: $qualityProcedureSource"
}

$modelCommonDestination = Join-Path $modelGithubRoot 'copilot-instructions-commun.md'
Sync-File -Source $commonInstructionsSource -Destination $modelCommonDestination

$targets = Get-TargetProjects

if (-not $targets -or $targets.Count -eq 0) {
    throw 'No target projects found for synchronization.'
}

Write-Step "Workspace root: $workspaceRoot" 'White'
Write-Step "Targets: $($targets.Name -join ', ')" 'White'

foreach ($project in $targets) {
    $projectGithubRoot = Join-Path $project.FullName '.github'
    $overlayType = Get-ProjectOverlay -ProjectRoot $project.FullName
    $projectGasOverlayDest = Join-Path $projectGithubRoot 'copilot-instructions-gas.md'
    $projectReactOverlayDest = Join-Path $projectGithubRoot 'copilot-instructions-react.md'

    if ($DryRun) {
        Write-Step "`n[DRY] Project $($project.Name)" 'Magenta'
    } else {
        Write-Step "`n[SYNC] Project $($project.Name)" 'Magenta'
    }

    Write-Step "[INFO] Overlay detecte: $overlayType" 'White'

    if (-not $SkipInstructions) {
        Sync-File -Source $commonInstructionsSource -Destination (Join-Path $projectGithubRoot 'copilot-instructions-commun.md')

        if ($overlayType -eq 'gas') {
            Sync-File -Source $overlayGasSource -Destination $projectGasOverlayDest
            Remove-FileIfExists -Path $projectReactOverlayDest -Label $projectReactOverlayDest
        } elseif ($overlayType -eq 'react') {
            Sync-File -Source $overlayReactSource -Destination $projectReactOverlayDest
            Remove-FileIfExists -Path $projectGasOverlayDest -Label $projectGasOverlayDest
        } else {
            Remove-FileIfExists -Path $projectGasOverlayDest -Label $projectGasOverlayDest
            Remove-FileIfExists -Path $projectReactOverlayDest -Label $projectReactOverlayDest
        }
    }

    Sync-File -Source $qualityProcedureSource -Destination (Join-Path $project.FullName '_governance\governance-quality-procedure.md')

    # R16: Merge canonical retro entries without replacing project-local entries.
    $modelDocsRetro = Join-Path $modelRoot 'docs\retro-modele.md'
    $projectDocsRetro = Join-Path $project.FullName 'docs\retro-modele.md'
    Merge-RetroModelFile -Source $modelDocsRetro -Destination $projectDocsRetro
    Ensure-ProjectStatus -Project $project

    if (-not $SkipAgents) {
        Sync-Directory -Source (Join-Path $modelGithubRoot 'agents') -Destination (Join-Path $projectGithubRoot 'agents')
        $legacyDeployer = Join-Path $projectGithubRoot 'agents\deployer.md'
        if (Test-Path (Join-Path $modelGithubRoot 'agents\deployer.agent.md')) {
            Remove-FileIfExists -Path $legacyDeployer -Label "$($project.Name) -> legacy deployer.md"
        }
    }

    Sync-Directory -Source (Join-Path $modelGithubRoot 'hooks') -Destination (Join-Path $projectGithubRoot 'hooks')

    if (-not $SkipSkills) {
        Sync-SkillDirectory -Source (Join-Path $modelGithubRoot 'skills') -Destination (Join-Path $projectGithubRoot 'skills') -ProjectRoot $project.FullName
    }

    # R15: Deploy agent/skill templates from _governance with "create if missing" behavior
    $templateMappings = @{
        'skill-check-account-template.md' = '.github\skills\check-account\SKILL.md'
        'skill-validate-syntax-template.md' = '.github\skills\validate-syntax\SKILL.md'
    }

    foreach ($sourceTemplate in $templateMappings.Keys) {
        $sourceFile = Join-Path $governanceRoot $sourceTemplate
        $destFile = Join-Path $project.FullName $templateMappings[$sourceTemplate]
        $templateLabel = "$($project.Name) → $($templateMappings[$sourceTemplate])"

        Sync-FileIfMissing -Source $sourceFile -Destination $destFile -Label $templateLabel
    }

    if (-not $SkipPrompts) {
        # D2: Sync individual prompt files with mapping (bonjour-prompt.md → bonjour.md, etc.)
        # These files come from _governance/, not modele-copilot/.github/prompts/
        $promptMappings = @{
            'bonjour-prompt.md' = 'bonjour.md'
            'core\\bonne-nuit-prompt.md' = 'bonne-nuit.md'
            'core\\retro-prompt.md' = 'retro.md'
        }

        foreach ($source in $promptMappings.Keys) {
            $sourceFile = Join-Path $governanceRoot $source
            $destFile = Join-Path $projectGithubRoot "prompts\$($promptMappings[$source])"

            if (Test-Path $sourceFile) {
                if ($DryRun) {
                    Write-Step "[DRY] create $destFile"
                } else {
                    $parent = Split-Path -Parent $destFile
                    if (-not (Test-Path $parent)) {
                        New-Item -ItemType Directory -Path $parent -Force | Out-Null
                    }
                    # D1 Fix: Use UTF8 encoding when copying prompt files
                    $content = Get-Content -Path $sourceFile -Raw -Encoding UTF8
                    Set-Content -Path $destFile -Value $content -NoNewline -Encoding UTF8
                    Write-Step "[OK]  File  $destFile" 'Green'
                }
            }
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
exit 0