[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$EntryPoint,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$FunctionName,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceExtensions = @('.js', '.gs')
$controlKeywords = @('if', 'for', 'while', 'switch', 'catch', 'with', 'function')

function Get-CodeMask {
    param([Parameter(Mandatory = $true)][string]$Content)

    $characters = $Content.ToCharArray()
    $state = 'Code'
    $singleQuote = [char]0x27
    $doubleQuote = [char]0x22
    $backtick = [char]0x60

    for ($index = 0; $index -lt $characters.Count; $index++) {
        $character = $characters[$index]
        $nextCharacter = if ($index + 1 -lt $characters.Count) { $characters[$index + 1] } else { [char]0 }

        if ($state -eq 'Code') {
            if ($character -eq '/' -and $nextCharacter -eq '/') {
                $characters[$index] = ' '
                $characters[$index + 1] = ' '
                $index++
                $state = 'LineComment'
            } elseif ($character -eq '/' -and $nextCharacter -eq '*') {
                $characters[$index] = ' '
                $characters[$index + 1] = ' '
                $index++
                $state = 'BlockComment'
            } elseif ($character -eq $singleQuote) {
                $characters[$index] = ' '
                $state = 'SingleQuote'
            } elseif ($character -eq $doubleQuote) {
                $characters[$index] = ' '
                $state = 'DoubleQuote'
            } elseif ($character -eq $backtick) {
                $characters[$index] = ' '
                $state = 'Template'
            }
            continue
        }

        if ($state -eq 'LineComment') {
            if ($character -eq "`r" -or $character -eq "`n") {
                $state = 'Code'
            } else {
                $characters[$index] = ' '
            }
            continue
        }

        if ($state -eq 'BlockComment') {
            if ($character -eq '*' -and $nextCharacter -eq '/') {
                $characters[$index] = ' '
                $characters[$index + 1] = ' '
                $index++
                $state = 'Code'
            } elseif ($character -ne "`r" -and $character -ne "`n") {
                $characters[$index] = ' '
            }
            continue
        }

        if ($character -eq '\') {
            $characters[$index] = ' '
            if ($index + 1 -lt $characters.Count -and $characters[$index + 1] -ne "`r" -and $characters[$index + 1] -ne "`n") {
                $characters[$index + 1] = ' '
                $index++
            }
            continue
        }

        if (($state -eq 'SingleQuote' -and $character -eq $singleQuote) -or
            ($state -eq 'DoubleQuote' -and $character -eq $doubleQuote) -or
            ($state -eq 'Template' -and $character -eq $backtick)) {
            $characters[$index] = ' '
            $state = 'Code'
        } elseif ($character -ne "`r" -and $character -ne "`n") {
            $characters[$index] = ' '
        }
    }

    return (-join $characters)
}

function Find-MatchingBrace {
    param(
        [Parameter(Mandatory = $true)][string]$MaskedContent,
        [Parameter(Mandatory = $true)][int]$OpenIndex
    )

    $depth = 0
    for ($index = $OpenIndex; $index -lt $MaskedContent.Length; $index++) {
        if ($MaskedContent[$index] -eq '{') {
            $depth++
        } elseif ($MaskedContent[$index] -eq '}') {
            $depth--
            if ($depth -eq 0) {
                return $index
            }
        }
    }

    throw "Unclosed function body at character $OpenIndex."
}

function Get-FunctionRecords {
    param(
        [Parameter(Mandatory = $true)][string]$MaskedContent,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $patterns = @(
        '(?m)\b(?:async\s+)?function\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*\([^)]*\)\s*\{',
        '(?m)\b(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(?:async\s+)?function(?:\s+[A-Za-z_$][A-Za-z0-9_$]*)?\s*\([^)]*\)\s*\{',
        '(?m)\b(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(?:async\s+)?(?:\([^)]*\)|[A-Za-z_$][A-Za-z0-9_$]*)\s*=>\s*\{'
    )
    $records = @()

    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($MaskedContent, $pattern)) {
            $relativeBraceIndex = $match.Value.IndexOf('{')
            if ($relativeBraceIndex -lt 0) {
                continue
            }

            $openIndex = $match.Index + $relativeBraceIndex
            $closeIndex = Find-MatchingBrace -MaskedContent $MaskedContent -OpenIndex $openIndex
            $lineNumber = ($MaskedContent.Substring(0, $openIndex) -split "`n").Count
            $name = $match.Groups[1].Value

            if (-not (@($records | Where-Object { $_.Name -eq $name -and $_.OpenIndex -eq $openIndex }).Count -gt 0)) {
                $records += [pscustomobject]@{
                    Name = $name
                    RelativePath = $RelativePath
                    Line = $lineNumber
                    OpenIndex = $openIndex
                    CloseIndex = $closeIndex
                    Body = $MaskedContent.Substring($openIndex + 1, $closeIndex - $openIndex - 1)
                }
            }
        }
    }

    return @($records)
}

function Get-SourceFiles {
    param([Parameter(Mandatory = $true)][string]$InputPath)

    $resolvedItem = Get-Item -LiteralPath $InputPath -ErrorAction Stop
    if ($resolvedItem.PSIsContainer) {
        $files = @(Get-ChildItem -LiteralPath $resolvedItem.FullName -Recurse -File -ErrorAction Stop | Where-Object {
                $sourceExtensions -contains $_.Extension.ToLowerInvariant() -and
                $_.FullName -notmatch '\\(?:node_modules|\.git)\\'
            })
    } else {
        if ($sourceExtensions -notcontains $resolvedItem.Extension.ToLowerInvariant()) {
            throw "Unsupported source extension: $($resolvedItem.Extension)"
        }
        $files = @($resolvedItem)
    }

    if ($files.Count -eq 0) {
        throw "No JavaScript or Apps Script source files found under $InputPath."
    }

    return $files
}

function Get-UncertaintyRecords {
    param(
        [Parameter(Mandatory = $true)][string]$MaskedContent,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $patterns = @(
        [pscustomobject]@{ Pattern = '\beval\s*\('; Reason = 'eval() can invoke a function dynamically.' },
        [pscustomobject]@{ Pattern = '\b(?:new\s+)?Function\s*\('; Reason = 'Function() can construct executable code dynamically.' },
        [pscustomobject]@{ Pattern = '\bReflect\.(?:apply|construct|get|set)\s*\('; Reason = 'Reflect can invoke or resolve a function dynamically.' },
        [pscustomobject]@{ Pattern = '\b[A-Za-z_$][A-Za-z0-9_$]*\s*\[[^\]\r\n]+\]\s*\('; Reason = 'Bracket property invocation can resolve a function dynamically.' }
    )
    $records = @()

    foreach ($item in $patterns) {
        foreach ($match in [regex]::Matches($MaskedContent, $item.Pattern)) {
            $lineNumber = ($MaskedContent.Substring(0, $match.Index) -split "`n").Count
            $records += [pscustomobject]@{
                File = $RelativePath
                Line = $lineNumber
                Reason = $item.Reason
            }
        }
    }

    return @($records | Sort-Object File, Line, Reason -Unique)
}

try {
    $sourceFiles = @((Get-SourceFiles -InputPath $Path) | Sort-Object FullName)
    $rootItem = Get-Item -LiteralPath $Path -ErrorAction Stop
    $basePath = if ($rootItem.PSIsContainer) { $rootItem.FullName.TrimEnd('\') + '\' } else { $rootItem.Directory.FullName.TrimEnd('\') + '\' }
    $functionRecords = @()
    $uncertaintyRecords = @()

    foreach ($sourceFile in $sourceFiles) {
        $content = Get-Content -LiteralPath $sourceFile.FullName -Raw -Encoding UTF8
        $maskedContent = Get-CodeMask -Content $content
        $relativePath = $sourceFile.FullName.Substring($basePath.Length)
        $functionRecords += Get-FunctionRecords -MaskedContent $maskedContent -RelativePath $relativePath
        $uncertaintyRecords += Get-UncertaintyRecords -MaskedContent $maskedContent -RelativePath $relativePath
    }

    if ($functionRecords.Count -eq 0) {
        throw 'No supported named functions found.'
    }

    $duplicateGroups = @($functionRecords | Group-Object Name | Where-Object { $_.Count -gt 1 })
    if ($duplicateGroups.Count -gt 0) {
        $duplicateNames = @($duplicateGroups | ForEach-Object Name) -join ', '
        throw "Duplicate function names are not supported: $duplicateNames"
    }

    $knownNames = @{}
    foreach ($functionRecord in $functionRecords) {
        $knownNames[$functionRecord.Name] = $true
    }
    if (-not $knownNames.ContainsKey($FunctionName)) {
        throw "Target function is not declared: $FunctionName"
    }

    $edges = @{}
    foreach ($functionRecord in $functionRecords) {
        $calledNames = @()
        $callEdges = @()
        foreach ($callMatch in [regex]::Matches($functionRecord.Body, '\b([A-Za-z_$][A-Za-z0-9_$]*)\s*\(')) {
            $calledName = $callMatch.Groups[1].Value
            $bodyPrefix = $functionRecord.Body.Substring(0, $callMatch.Index)
            if ($bodyPrefix -match 'function\s*$') {
                continue
            }
            if ($knownNames.ContainsKey($calledName) -and $controlKeywords -notcontains $calledName) {
                $calledNames += $calledName
                $callLine = $functionRecord.Line + (($bodyPrefix -split "`n").Count - 1)
                $callEdges += [pscustomobject]@{
                    Name = $calledName
                    File = $functionRecord.RelativePath
                    Line = $callLine
                }
            }
        }
        $edges[$functionRecord.Name] = @($callEdges | Sort-Object Name, File, Line -Unique)
    }

    $reachableNames = @()
    $pendingNames = @()
    $parentNames = @{}
    $parentEdges = @{}
    $entryPoints = @($EntryPoint | Sort-Object -Unique)
    foreach ($entryPointName in @($entryPoints | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        if (-not $knownNames.ContainsKey($entryPointName)) {
            throw "Entry point is not declared: $entryPointName"
        }
        if (-not ($reachableNames -contains $entryPointName)) {
            $reachableNames += $entryPointName
            $pendingNames += $entryPointName
        }
    }

    while ($pendingNames.Count -gt 0) {
        $currentName = $pendingNames[0]
        if ($pendingNames.Count -eq 1) {
            $pendingNames = @()
        } else {
            $pendingNames = @($pendingNames[1..($pendingNames.Count - 1)])
        }
        foreach ($callEdge in @($edges[$currentName])) {
            if (-not ($reachableNames -contains $callEdge.Name)) {
                $parentNames[$callEdge.Name] = $currentName
                $parentEdges[$callEdge.Name] = $callEdge
                $reachableNames += $callEdge.Name
                $pendingNames += $callEdge.Name
            }
        }
    }

    $recordByName = @{}
    foreach ($functionRecord in $functionRecords) {
        $recordByName[$functionRecord.Name] = $functionRecord
    }

    $callChain = New-Object 'System.Collections.Generic.List[object]'
    if ($reachableNames -contains $FunctionName) {
        $currentName = $FunctionName
        while ($true) {
            $currentRecord = $recordByName[$currentName]
            if ($parentNames.ContainsKey($currentName)) {
                $parentName = $parentNames[$currentName]
                $parentRecord = $recordByName[$parentName]
                $callEdge = $parentEdges[$currentName]
                $callChain.Insert(0, [ordered]@{
                        function = $currentName
                        definition = ($currentRecord.RelativePath + ':' + $currentRecord.Line)
                        from_function = $parentName
                        from_definition = ($parentRecord.RelativePath + ':' + $parentRecord.Line)
                        call_site = ($callEdge.File + ':' + $callEdge.Line)
                    })
                $currentName = $parentName
            } else {
                $callChain.Insert(0, [ordered]@{
                        function = $currentName
                        definition = ($currentRecord.RelativePath + ':' + $currentRecord.Line)
                        from_function = ''
                        from_definition = ''
                        call_site = ''
                    })
                break
            }
        }
    }

    $chainText = ''
    if ($callChain.Count -gt 0) {
        $chainText = ($callChain | ForEach-Object {
                if ($_.from_function) {
                    $_.from_function + ' [' + $_.from_definition + '] --' + $_.call_site + '--> ' + $_.function + ' [' + $_.definition + ']'
                } else {
                    $_.function + ' [' + $_.definition + '] (entry point)'
                }
            }) -join ' ; '
    }

    $sortedRecords = @($functionRecords | Sort-Object RelativePath, Line, Name)
    $targetRecord = $recordByName[$FunctionName]
    if ($uncertaintyRecords.Count -gt 0) {
        $verdict = 'UNCERTAIN'
        $proof = 'UNCERTAIN: ' + (($uncertaintyRecords | ForEach-Object { $_.File + ':' + $_.Line + ' ' + $_.Reason }) -join ' ; ')
    } elseif ($reachableNames -contains $FunctionName) {
        $verdict = 'PASS'
        $proof = 'CALL CHAIN: ' + $chainText
    } else {
        $verdict = 'FAIL'
        $proof = 'SCANNED ENTRY POINTS: ' + ($entryPoints -join ', ') + '; no static call chain reaches ' + $FunctionName + '.'
    }

    $result = [ordered]@{
        gate_id = 'fonction-orpheline'
        verdict = $verdict
        path = (Resolve-Path -LiteralPath $Path).Path
        target_function = $FunctionName
        scanned_entry_points = $entryPoints
        files = $sourceFiles.Count
        functions = $sortedRecords.Count
        reachable = @($reachableNames)
        call_chain = @($callChain.ToArray())
        uncertainties = @($uncertaintyRecords | ForEach-Object {
                [ordered]@{ file = $_.File; line = $_.Line; reason = $_.Reason }
            })
        proof = $proof
    }

    if ($Json) {
        Write-Output ($result | ConvertTo-Json -Depth 6)
    } else {
        Write-Output ('ORPHAN-FUNCTION-GATE ' + $verdict)
        Write-Output ('Path: ' + $result.path)
        Write-Output ('Target function: ' + $FunctionName)
        Write-Output ('SCANNED ENTRY POINTS: ' + ($entryPoints -join ', '))
        Write-Output ('Files: ' + $result.files + ' | Functions: ' + $result.functions + ' | Reachable: ' + $result.reachable.Count)
        if ($callChain.Count -gt 0) {
            Write-Output ('CALL CHAIN: ' + $chainText)
        }
        foreach ($uncertainty in $uncertaintyRecords) {
            Write-Output ('UNCERTAINTY: ' + $uncertainty.File + ':' + $uncertainty.Line + ' ' + $uncertainty.Reason)
        }
        Write-Output ('PROOF: ' + $proof)
    }

    if ($verdict -eq 'FAIL') {
        exit 1
    }
    if ($verdict -eq 'UNCERTAIN') {
        exit 2
    }
    exit 0
} catch {
    Write-Output ('ORPHAN-FUNCTION-GATE ERROR: ' + $_.Exception.Message)
    exit 2
}