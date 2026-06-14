<#
.SYNOPSIS
    Integre la couche Copilot du modele dans un projet existant, sans deploiement.

.DESCRIPTION
    - Verifie le projet cible et son etat Git.
    - Copie la couche .github canonique du modele.
    - Ajoute les docs de gouvernance et securite si absentes.
    - Si une doc existe deja, depose une copie de comparaison dans docs/copilot-governance/to-merge/.
    - Lance un controle simple des secrets en dur.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [switch]$DryRun,
    [switch]$UiProject
)

$modelRoot = $PSScriptRoot
$workspaceRoot = Split-Path -Parent $modelRoot
$resolvedProjectPath = Resolve-Path -Path $ProjectPath -ErrorAction Stop
$projectRoot = $resolvedProjectPath.Path
$projectName = Split-Path -Leaf $projectRoot

if ($projectRoot -eq $modelRoot) {
    throw 'Target project cannot be modele-copilot itself.'
}

$sourceGithubRoot = Join-Path $modelRoot '.github'
$sourceProjectDocsRoot = Join-Path $modelRoot 'docs\project'
$sourceSecurityDocsRoot = Join-Path $modelRoot 'docs\security'

$targetGithubRoot = Join-Path $projectRoot '.github'
$targetProjectDocsRoot = Join-Path $projectRoot 'docs\project'
$targetSecurityDocsRoot = Join-Path $projectRoot 'docs\security'
$targetReviewRoot = Join-Path $projectRoot 'docs\copilot-governance\to-merge'

$script:summary = [ordered]@{
    AddedDocs = New-Object System.Collections.Generic.List[string]
    ReviewDocs = New-Object System.Collections.Generic.List[string]
    ReplacedAssets = New-Object System.Collections.Generic.List[string]
    SecretFindings = New-Object System.Collections.Generic.List[string]
}

function Write-Step {
    param(
        [string]$Message,
        [string]$Color = 'Cyan'
    )

    Write-Host $Message -ForegroundColor $Color
}

function Ensure-Directory {
    param([string]$Path)

    if ($DryRun) {
        return
    }

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-ReplacingDirectory {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Label
    )

    if ($DryRun) {
        Write-Step "[DRY] Replace $Label -> $Destination"
        return
    }

    $parent = Split-Path -Parent $Destination
    Ensure-Directory -Path $parent

    if (Test-Path $Destination) {
        Remove-Item -Path $Destination -Recurse -Force
    }

    Copy-Item -Path $Source -Destination $parent -Recurse -Force
    $script:summary.ReplacedAssets.Add($Label) | Out-Null
    Write-Step "[OK]  Replace $Label" 'Green'
}

function Copy-ReplacingFile {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Label
    )

    if ($DryRun) {
        Write-Step "[DRY] Replace $Label -> $Destination"
        return
    }

    $parent = Split-Path -Parent $Destination
    Ensure-Directory -Path $parent

    Copy-Item -Path $Source -Destination $Destination -Force
    $script:summary.ReplacedAssets.Add($Label) | Out-Null
    Write-Step "[OK]  Replace $Label" 'Green'
}

function Copy-DocSafely {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$RelativeLabel
    )

    if (-not (Test-Path $Destination)) {
        if ($DryRun) {
            Write-Step "[DRY] Add doc $RelativeLabel"
            return
        }

        $parent = Split-Path -Parent $Destination
        Ensure-Directory -Path $parent
        Copy-Item -Path $Source -Destination $Destination -Force
        $script:summary.AddedDocs.Add($RelativeLabel) | Out-Null
        Write-Step "[OK]  Add doc $RelativeLabel" 'Green'
        return
    }

    $sourceHash = (Get-FileHash -Path $Source -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -Path $Destination -Algorithm SHA256).Hash
    if ($sourceHash -eq $destinationHash) {
        Write-Step "[OK]  Keep doc $RelativeLabel (already aligned)" 'DarkGreen'
        return
    }

    $reviewDestination = Join-Path $targetReviewRoot $RelativeLabel
    if ($DryRun) {
        Write-Step "[DRY] Review doc $RelativeLabel -> $reviewDestination" 'Yellow'
        return
    }

    $reviewParent = Split-Path -Parent $reviewDestination
    Ensure-Directory -Path $reviewParent
    Copy-Item -Path $Source -Destination $reviewDestination -Force
    $script:summary.ReviewDocs.Add($RelativeLabel) | Out-Null
    Write-Step "[REVIEW] Existing doc kept, template copied for merge: $RelativeLabel" 'Yellow'
}

function Test-BasicSecrets {
    param([string]$RootPath)

    $rg = Get-Command rg -ErrorAction SilentlyContinue
    $patterns = @(
        '(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*["''][^"'']+["'']',
        'AKIA[0-9A-Z]{16}',
        'ghp_[A-Za-z0-9]{36,}',
        'AIza[0-9A-Za-z\-_]{20,}'
    )

    if ($rg) {
        foreach ($pattern in $patterns) {
            $matches = & $rg.Source --glob '!**/.git/**' --glob '!**/node_modules/**' --glob '!**/.clasp.json' -n -S -e $pattern $RootPath 2>$null
            if ($LASTEXITCODE -eq 0 -and $matches) {
                foreach ($match in $matches) {
                    $script:summary.SecretFindings.Add($match) | Out-Null
                }
            }
        }
    } else {
        $allowedExtensions = @(
            '.js', '.ts', '.tsx', '.jsx', '.json', '.html', '.css', '.scss', '.md', '.txt',
            '.yml', '.yaml', '.ps1', '.mjs', '.cjs', '.xml', '.env', '.sh'
        )

        $files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -notmatch '\\.git\\' -and
                $_.FullName -notmatch '\\node_modules\\' -and
                $_.Name -ne '.clasp.json' -and
                $allowedExtensions -contains $_.Extension
            }

        foreach ($pattern in $patterns) {
            $matches = $files | Select-String -Pattern $pattern -AllMatches -ErrorAction SilentlyContinue
            foreach ($match in $matches) {
                $script:summary.SecretFindings.Add("$($match.Path):$($match.LineNumber):$($match.Line.Trim())") | Out-Null
            }
        }
    }

    if ($script:summary.SecretFindings.Count -eq 0) {
        Write-Step '[OK]  No obvious hard-coded secret pattern found.' 'Green'
    } else {
        Write-Step "[WARN] Secret scan found $($script:summary.SecretFindings.Count) possible match(es)." 'Yellow'
    }
}

function Show-GitState {
    param([string]$RootPath)

    Write-Step "Project: $projectName" 'White'
    Write-Step "Path: $RootPath" 'White'

    if (-not (Test-Path (Join-Path $RootPath '.git'))) {
        Write-Step '[WARN] No .git directory found in target project.' 'Yellow'
        return
    }

    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        Write-Step '[WARN] Git command not available.' 'Yellow'
        return
    }

    $branch = & $git.Source -C $RootPath branch --show-current 2>$null
    $remote = & $git.Source -C $RootPath remote -v 2>$null | Select-Object -First 1
    $status = & $git.Source -C $RootPath status --short 2>$null

    Write-Step "Git branch: $branch" 'White'
    if ($remote) {
        Write-Step "Git remote: $remote" 'White'
    } else {
        Write-Step '[WARN] No Git remote configured.' 'Yellow'
    }

    if ($status) {
        Write-Step '[WARN] Working tree not clean.' 'Yellow'
    } else {
        Write-Step '[OK]  Working tree clean.' 'Green'
    }
}

Write-Step '=== Existing Project Governance Kit ===' 'Magenta'
Show-GitState -RootPath $projectRoot

Copy-ReplacingFile -Source (Join-Path $sourceGithubRoot 'copilot-instructions.md') -Destination (Join-Path $targetGithubRoot 'copilot-instructions.md') -Label '.github/copilot-instructions.md'
Copy-ReplacingDirectory -Source (Join-Path $sourceGithubRoot 'agents') -Destination (Join-Path $targetGithubRoot 'agents') -Label '.github/agents/'
Copy-ReplacingDirectory -Source (Join-Path $sourceGithubRoot 'skills') -Destination (Join-Path $targetGithubRoot 'skills') -Label '.github/skills/'

$projectDocs = @(
    'startup-kit.md',
    'decision-log.md',
    'operating-rules.md',
    'requirements-matrix.md',
    'roadmap.md',
    'glossary.md',
    'architecture-standards.md'
)

if ($UiProject) {
    $projectDocs += @('frontend-patterns.md', 'charte-graphique.md')
}

foreach ($docName in $projectDocs) {
    Copy-DocSafely -Source (Join-Path $sourceProjectDocsRoot $docName) -Destination (Join-Path $targetProjectDocsRoot $docName) -RelativeLabel (Join-Path 'project' $docName)
}

$securityDocs = @(
    'cybersecurity-baseline.md',
    'robustesse-scalabilite.md'
)

foreach ($docName in $securityDocs) {
    Copy-DocSafely -Source (Join-Path $sourceSecurityDocsRoot $docName) -Destination (Join-Path $targetSecurityDocsRoot $docName) -RelativeLabel (Join-Path 'security' $docName)
}

Test-BasicSecrets -RootPath $projectRoot

Write-Step "`nSummary" 'Magenta'
Write-Step "Replaced assets: $($script:summary.ReplacedAssets.Count)" 'White'
Write-Step "Added docs: $($script:summary.AddedDocs.Count)" 'White'
Write-Step "Docs to merge manually: $($script:summary.ReviewDocs.Count)" 'White'
Write-Step "Secret findings: $($script:summary.SecretFindings.Count)" 'White'

if ($script:summary.ReviewDocs.Count -gt 0) {
    Write-Step 'Docs copied for review under docs/copilot-governance/to-merge/.' 'Yellow'
}

Write-Step 'No deployment performed.' 'White'