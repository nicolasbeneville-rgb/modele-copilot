param(
    [string]$PayloadJson = ''
)
$ErrorActionPreference = 'Continue'
$raw = if ($PayloadJson) { $PayloadJson } else { [Console]::In.ReadToEnd() }
try { $payload = $raw | ConvertFrom-Json } catch { Write-Error 'Pre-action hook received invalid JSON.'; exit 2 }

$readOnlyTools = @(
    'read_file', 'file_search', 'grep_search', 'get_errors', 'list_dir',
    'view_image', 'vscode_listCodeUsages', 'vscode_askQuestions',
    'manage_todo_list', 'fetch_webpage', 'runSubagent'
)
$toolName = [string]$payload.tool_name
$toolInputText = if ($null -ne $payload.tool_input) { $payload.tool_input | ConvertTo-Json -Depth 12 -Compress } else { '' }
if ($readOnlyTools -contains $toolName) { exit 0 }
if ($toolInputText -match '(?i)(action-plan\.yaml|projet-status\.yaml)') { exit 0 }

$cwd = if ($payload.cwd) { [string]$payload.cwd } else { (Get-Location).Path }
$plan = ''
$cursor = (Resolve-Path $cwd -ErrorAction SilentlyContinue).Path
while ($cursor) {
    $projectPlan = Join-Path $cursor 'projet-status.yaml'
    if (Test-Path $projectPlan) { $plan = $projectPlan; break }
    $workspacePlan = Join-Path $cursor '_governance\action-plan.yaml'
    if (Test-Path $workspacePlan) { $plan = $workspacePlan; break }
    $parent = Split-Path -Parent $cursor
    if ($parent -eq $cursor) { break }
    $cursor = $parent
}
if (-not $plan) { Write-Error 'ACTION PLAN BLOCKED: create projet-status.yaml or _governance/action-plan.yaml first.'; exit 2 }

$content = Get-Content -Path $plan -Raw -Encoding UTF8
$required = @(
    'id','status','objective','scope','critical_path','risks','rollback','tests',
    'feedback_loop','learning','integration_check','human_gate','human_value','acceptance',
    'mode','routing','agents','skills','arbitrations','retirements','parallel_dispatch',
    'phase','vision','challenge','clarification_status','global_plan','epics','user_stories',
    'tasks','test_level','test_matrix','quality_dimensions',
    'foundations_version_start','foundations_version_at_completion','foundations_version_change',
    'foundations_version_confirmation','live_test_required','live_test_procedure','live_test_status',
    'live_test_evidence'
)
$missing = @()
foreach ($field in $required) {
    $fieldMatch = [regex]::Match($content, '(?m)^\s+' + [regex]::Escape($field) + ':\s*(.*)$')
    if (-not $fieldMatch.Success -or [string]::IsNullOrWhiteSpace($fieldMatch.Groups[1].Value) -or $fieldMatch.Groups[1].Value -match '(?i)<[^>]+>|TO_CONFIRM|TODO|TBD') { $missing += $field }
}
$statusMatch = [regex]::Match($content, '(?m)^\s+status:\s*([^\r\n]+)')
$status = if ($statusMatch.Success) { $statusMatch.Groups[1].Value.Trim().Trim('"').ToLowerInvariant() } else { '' }
if ($status -notin @('planned','in_progress')) { $missing += "status=$status" }
if ($missing.Count) { Write-Error ("ACTION PLAN BLOCKED: " + ($missing -join ', ')); exit 2 }
$phaseMatch = [regex]::Match($content, '(?m)^\s+phase:\s*([^\r\n]+)')
$planPhase = if ($phaseMatch.Success) { $phaseMatch.Groups[1].Value.Trim().Trim('"').ToLowerInvariant() } else { '' }
$clarificationMatch = [regex]::Match($content, '(?m)^\s+clarification_status:\s*([^\r\n]+)')
$clarificationStatus = if ($clarificationMatch.Success) { $clarificationMatch.Groups[1].Value.Trim().Trim('"').ToLowerInvariant() } else { '' }
if ($planPhase -notin @('discovery', 'planned', 'execution', 'verification', 'release')) { Write-Error "ACTION PLAN BLOCKED: invalid phase '$planPhase'."; exit 2 }
if ($clarificationStatus -notin @('open', 'clarified', 'blocked')) { Write-Error "ACTION PLAN BLOCKED: invalid clarification_status '$clarificationStatus'."; exit 2 }
if ($planPhase -in @('execution', 'verification', 'release') -and $clarificationStatus -ne 'clarified') { Write-Error "ACTION PLAN BLOCKED: clarification must be clarified before $planPhase."; exit 2 }
exit 0
