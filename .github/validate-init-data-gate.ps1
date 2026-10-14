[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceExtensions = @('.js', '.gs')

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

    if (@($files).Count -eq 0) {
        throw "No JavaScript or Apps Script source files found under $InputPath."
    }

    return ,@($files | Sort-Object FullName)
}

function ConvertFrom-JavaScriptString {
    param([AllowEmptyString()][Parameter(Mandatory = $true)][string]$RawValue)

    $builder = New-Object System.Text.StringBuilder
    for ($position = 0; $position -lt $RawValue.Length; $position++) {
        $character = $RawValue[$position]
        if ($character -ne '\' -or $position + 1 -ge $RawValue.Length) {
            [void]$builder.Append($character)
            continue
        }

        $position++
        $escaped = $RawValue[$position]
        switch ($escaped) {
            '\' { [void]$builder.Append('\') }
            "'" { [void]$builder.Append("'") }
            '"' { [void]$builder.Append('"') }
            'n' { [void]$builder.Append("`n") }
            'r' { [void]$builder.Append("`r") }
            't' { [void]$builder.Append("`t") }
            'b' { [void]$builder.Append([char]0x08) }
            'f' { [void]$builder.Append([char]0x0C) }
            'v' { [void]$builder.Append([char]0x0B) }
            '0' { [void]$builder.Append([char]0) }
            'x' {
                if ($position + 2 -lt $RawValue.Length -and $RawValue.Substring($position + 1, 2) -match '^[0-9A-Fa-f]{2}$') {
                    $position += 2
                    [void]$builder.Append([char][Convert]::ToInt32($RawValue.Substring($position - 1, 2), 16))
                } else {
                    [void]$builder.Append('x')
                }
            }
            'u' {
                if ($position + 4 -lt $RawValue.Length -and $RawValue.Substring($position + 1, 4) -match '^[0-9A-Fa-f]{4}$') {
                    $position += 4
                    [void]$builder.Append([char][Convert]::ToInt32($RawValue.Substring($position - 3, 4), 16))
                } else {
                    [void]$builder.Append('u')
                }
            }
            default { [void]$builder.Append($escaped) }
        }
    }

    return $builder.ToString()
}

function Get-CodeTokens {
    param(
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $tokens = New-Object 'System.Collections.Generic.List[object]'
    $uncertainties = New-Object 'System.Collections.Generic.List[object]'
    $index = 0
    $line = 1

    while ($index -lt $Content.Length) {
        $character = $Content[$index]
        $nextCharacter = if ($index + 1 -lt $Content.Length) { $Content[$index + 1] } else { [char]0 }

        if ([char]::IsWhiteSpace($character)) {
            if ($character -eq "`n") {
                $line++
            }
            $index++
            continue
        }

        if ($character -eq '/' -and $nextCharacter -eq '/') {
            $index += 2
            while ($index -lt $Content.Length -and $Content[$index] -ne "`n") {
                $index++
            }
            continue
        }

        if ($character -eq '/' -and $nextCharacter -eq '*') {
            $index += 2
            while ($index -lt $Content.Length) {
                if ($Content[$index] -eq "`n") {
                    $line++
                }
                if ($Content[$index] -eq '*' -and $index + 1 -lt $Content.Length -and $Content[$index + 1] -eq '/') {
                    $index += 2
                    break
                }
                $index++
            }
            continue
        }

        if ($character -eq "'" -or $character -eq '"') {
            $quote = $character
            $tokenLine = $line
            $index++
            $rawValue = New-Object System.Text.StringBuilder
            $closed = $false
            while ($index -lt $Content.Length) {
                $current = $Content[$index]
                if ($current -eq $quote) {
                    $closed = $true
                    $index++
                    break
                }
                if ($current -eq '\' -and $index + 1 -lt $Content.Length) {
                    [void]$rawValue.Append($current)
                    $index++
                    $current = $Content[$index]
                    [void]$rawValue.Append($current)
                    if ($current -eq "`n") {
                        $line++
                    }
                    $index++
                    continue
                }
                if ($current -eq "`n") {
                    $line++
                    break
                }
                [void]$rawValue.Append($current)
                $index++
            }

            if (-not $closed) {
                $uncertainties.Add([pscustomobject]@{
                        File = $RelativePath
                        Line = $tokenLine
                        Reason = 'Unterminated string literal prevents reliable scanning.'
                    })
            } else {
                $tokens.Add([pscustomobject]@{
                        Type = 'String'
                        Value = (ConvertFrom-JavaScriptString -RawValue $rawValue.ToString())
                        Line = $tokenLine
                    })
            }
            continue
        }

        if ($character -eq '`') {
            $templateLine = $line
            $index++
            $templateContent = New-Object System.Text.StringBuilder
            $closed = $false
            while ($index -lt $Content.Length) {
                $current = $Content[$index]
                if ($current -eq '`') {
                    $closed = $true
                    $index++
                    break
                }
                if ($current -eq '\' -and $index + 1 -lt $Content.Length) {
                    [void]$templateContent.Append($current)
                    $index++
                    $current = $Content[$index]
                }
                if ($current -eq "`n") {
                    $line++
                }
                [void]$templateContent.Append($current)
                $index++
            }
            if ($templateContent.ToString().Contains('${')) {
                $uncertainties.Add([pscustomobject]@{
                        File = $RelativePath
                        Line = $templateLine
                        Reason = 'Template interpolation is not analyzed.'
                    })
            }
            if (-not $closed) {
                $uncertainties.Add([pscustomobject]@{
                        File = $RelativePath
                        Line = $templateLine
                        Reason = 'Unterminated template literal prevents reliable scanning.'
                    })
            }
            continue
        }

        if ([char]::IsLetter($character) -or $character -eq '_' -or $character -eq '$') {
            $start = $index
            while ($index -lt $Content.Length -and
                ([char]::IsLetterOrDigit($Content[$index]) -or $Content[$index] -eq '_' -or $Content[$index] -eq '$')) {
                $index++
            }
            $tokens.Add([pscustomobject]@{
                    Type = 'Identifier'
                    Value = $Content.Substring($start, $index - $start)
                    Line = $line
                })
            continue
        }

        $value = [string]$character
        if ($index + 1 -lt $Content.Length) {
            $pair = $Content.Substring($index, 2)
            if (@('||', '??', '?.', '=>', '==', '!=', '&&', '++', '--') -contains $pair) {
                $value = $pair
                $index++
            }
        }
        $tokens.Add([pscustomobject]@{
                Type = 'Punctuation'
                Value = $value
                Line = $line
            })
        $index++
    }

    return [pscustomobject]@{
        Tokens = $tokens.ToArray()
        Uncertainties = $uncertainties.ToArray()
    }
}

function Find-MatchingToken {
    param(
        [Parameter(Mandatory = $true)][object[]]$Tokens,
        [Parameter(Mandatory = $true)][int]$StartIndex,
        [Parameter(Mandatory = $true)][string]$OpenValue,
        [Parameter(Mandatory = $true)][string]$CloseValue
    )

    $depth = 0
    for ($position = $StartIndex; $position -lt $Tokens.Count; $position++) {
        if ($Tokens[$position].Value -eq $OpenValue) {
            $depth++
        } elseif ($Tokens[$position].Value -eq $CloseValue) {
            $depth--
            if ($depth -eq 0) {
                return $position
            }
        }
    }
    return -1
}

function Get-FirstCallArgument {
    param(
        [Parameter(Mandatory = $true)][object[]]$Tokens,
        [Parameter(Mandatory = $true)][int]$OpenIndex
    )

    $start = $OpenIndex + 1
    $parentheses = 0
    $brackets = 0
    $braces = 0
    for ($position = $start; $position -lt $Tokens.Count; $position++) {
        $value = $Tokens[$position].Value
        if ($value -eq '(') { $parentheses++ }
        elseif ($value -eq ')') {
            if ($parentheses -eq 0 -and $brackets -eq 0 -and $braces -eq 0) {
                $argument = @()
                if ($position -gt $start) { $argument = @($Tokens[$start..($position - 1)]) }
                return [pscustomobject]@{ Tokens = $argument; CloseIndex = $position }
            }
            $parentheses--
        } elseif ($value -eq '[') { $brackets++ }
        elseif ($value -eq ']') { $brackets-- }
        elseif ($value -eq '{') { $braces++ }
        elseif ($value -eq '}') { $braces-- }
        elseif ($value -eq ',' -and $parentheses -eq 0 -and $brackets -eq 0 -and $braces -eq 0) {
            $argument = @()
            if ($position -gt $start) { $argument = @($Tokens[$start..($position - 1)]) }
            return [pscustomobject]@{ Tokens = $argument; CloseIndex = -1 }
        }
    }

    return [pscustomobject]@{ Tokens = @(); CloseIndex = -1 }
}

function Add-Uncertainty {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$Collection,
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][int]$Line,
        [Parameter(Mandatory = $true)][string]$Reason
    )

    $Collection.Add([pscustomobject]@{ File = $File; Line = $Line; Reason = $Reason })
}

function Add-Initialization {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$Collection,
        [Parameter(Mandatory = $true)][string]$Kind,
        [AllowEmptyString()][Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][int]$Line,
        [bool]$IsDefault = $false
    )

    $Collection.Add([pscustomobject]@{
            Kind = $Kind
            Name = $Name
            File = $File
            Line = $Line
            IsDefault = $IsDefault
        })
}

function Add-ObjectLiteralInitializations {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][object[]]$ArgumentTokens,
        [Parameter(Mandatory = $true)][string]$File,
        [Parameter(Mandatory = $true)][int]$Line,
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$Initializations,
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$Uncertainties
    )

    if ($ArgumentTokens.Count -lt 2 -or $ArgumentTokens[0].Value -ne '{' -or $ArgumentTokens[$ArgumentTokens.Count - 1].Value -ne '}') {
        Add-Uncertainty -Collection $Uncertainties -File $File -Line $Line -Reason 'setProperties() argument is not a literal object.'
        return
    }

    $matchingBrace = Find-MatchingToken -Tokens $ArgumentTokens -StartIndex 0 -OpenValue '{' -CloseValue '}'
    if ($matchingBrace -ne $ArgumentTokens.Count - 1) {
        Add-Uncertainty -Collection $Uncertainties -File $File -Line $Line -Reason 'setProperties() argument is not a single literal object.'
        return
    }

    $position = 1
    while ($position -lt $ArgumentTokens.Count - 1) {
        if ($ArgumentTokens[$position].Value -eq ',') {
            $position++
            continue
        }

        $keyToken = $ArgumentTokens[$position]
        if (($keyToken.Type -ne 'Identifier' -and $keyToken.Type -ne 'String') -or
            $position + 1 -ge $ArgumentTokens.Count -or $ArgumentTokens[$position + 1].Value -ne ':') {
            Add-Uncertainty -Collection $Uncertainties -File $File -Line $keyToken.Line -Reason 'setProperties() contains a non-literal or unsupported object key.'
            while ($position -lt $ArgumentTokens.Count - 1 -and $ArgumentTokens[$position].Value -ne ',') { $position++ }
            continue
        }

        $name = [string]$keyToken.Value
        $position += 2
        $valueStart = $position
        $parentheses = 0
        $brackets = 0
        $braces = 0
        while ($position -lt $ArgumentTokens.Count - 1) {
            $value = $ArgumentTokens[$position].Value
            if ($value -eq '(') { $parentheses++ }
            elseif ($value -eq ')') { $parentheses-- }
            elseif ($value -eq '[') { $brackets++ }
            elseif ($value -eq ']') { $brackets-- }
            elseif ($value -eq '{') { $braces++ }
            elseif ($value -eq '}') { $braces-- }
            elseif ($value -eq ',' -and $parentheses -eq 0 -and $brackets -eq 0 -and $braces -eq 0) { break }
            $position++
        }

        if ($position -eq $valueStart) {
            Add-Uncertainty -Collection $Uncertainties -File $File -Line $keyToken.Line -Reason 'setProperties() object entry has no value.'
        } else {
            Add-Initialization -Collection $Initializations -Kind 'property' -Name $name -File $File -Line $keyToken.Line
        }
    }
}

try {
    $sourceFiles = @((Get-SourceFiles -InputPath $Path))
    $rootItem = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($rootItem.PSIsContainer) {
        $basePath = $rootItem.FullName.TrimEnd('\') + '\'
    } else {
        $basePath = $rootItem.Directory.FullName.TrimEnd('\') + '\'
    }

    $reads = New-Object 'System.Collections.Generic.List[object]'
    $initializations = New-Object 'System.Collections.Generic.List[object]'
    $uncertainties = New-Object 'System.Collections.Generic.List[object]'

    foreach ($sourceFile in $sourceFiles) {
        $content = Get-Content -LiteralPath $sourceFile.FullName -Raw -Encoding UTF8
        $relativePath = $sourceFile.FullName.Substring($basePath.Length)
        $lexed = Get-CodeTokens -Content ([string]$content) -RelativePath $relativePath
        foreach ($uncertainty in @($lexed.Uncertainties)) {
            $uncertainties.Add($uncertainty)
        }
        $tokens = @($lexed.Tokens)

        for ($position = 0; $position -lt $tokens.Count; $position++) {
            $token = $tokens[$position]
            if ($token.Type -ne 'Identifier' -or $position -eq 0 -or $tokens[$position - 1].Value -notin @('.', '?.')) {
                continue
            }
            if ($position + 1 -ge $tokens.Count -or $tokens[$position + 1].Value -ne '(') {
                continue
            }

            $method = [string]$token.Value
            if ($method -notin @('getSheetByName', 'getProperty', 'insertSheet', 'setProperty', 'setProperties')) {
                continue
            }

            $argumentInfo = Get-FirstCallArgument -Tokens $tokens -OpenIndex ($position + 1)
            $argumentTokens = @($argumentInfo.Tokens)
            $kind = if ($method -in @('getSheetByName', 'insertSheet')) { 'sheet' } else { 'property' }
            $isRead = $method -in @('getSheetByName', 'getProperty')
            $isLiteral = $argumentTokens.Count -eq 1 -and $argumentTokens[0].Type -eq 'String'

            if ($method -eq 'setProperties') {
                Add-ObjectLiteralInitializations -ArgumentTokens $argumentTokens -File $relativePath -Line $token.Line -Initializations $initializations -Uncertainties $uncertainties
                continue
            }

            if ($isRead) {
                $reads.Add([pscustomobject]@{
                        Kind = $kind
                        Name = if ($isLiteral) { [string]$argumentTokens[0].Value } else { '' }
                        File = $relativePath
                        Line = $token.Line
                        IsLiteral = $isLiteral
                        DefaultLine = 0
                    })
            }

            if (-not $isLiteral) {
                Add-Uncertainty -Collection $uncertainties -File $relativePath -Line $token.Line -Reason "$method() argument is not a single string literal."
                continue
            }

            if (-not $isRead) {
                Add-Initialization -Collection $initializations -Kind $kind -Name ([string]$argumentTokens[0].Value) -File $relativePath -Line $token.Line
            } elseif ($method -eq 'getProperty' -and $argumentInfo.CloseIndex -ge 0 -and $argumentInfo.CloseIndex + 1 -lt $tokens.Count -and $tokens[$argumentInfo.CloseIndex + 1].Value -in @('||', '??')) {
                $defaultLine = $tokens[$argumentInfo.CloseIndex + 1].Line
                $reads[$reads.Count - 1].DefaultLine = $defaultLine
                Add-Initialization -Collection $initializations -Kind 'property' -Name ([string]$argumentTokens[0].Value) -File $relativePath -Line $defaultLine -IsDefault $true
            }
        }
    }

    $missing = New-Object 'System.Collections.Generic.List[object]'
    $proofs = New-Object 'System.Collections.Generic.List[object]'
    foreach ($read in $reads) {
        if (-not $read.IsLiteral) {
            continue
        }

        $matches = @($initializations | Where-Object { $_.Kind -eq $read.Kind -and $_.Name -ceq $read.Name })
        if ($matches.Count -eq 0) {
            $missing.Add($read)
            continue
        }

        $explicitMatches = @($matches | Where-Object { -not $_.IsDefault } | Sort-Object File, Line)
        $initialization = if ($explicitMatches.Count -gt 0) { $explicitMatches[0] } else { @($matches | Sort-Object File, Line)[0] }
        $proofs.Add([pscustomobject]@{
                Kind = $read.Kind
                Name = $read.Name
                ReadFile = $read.File
                ReadLine = $read.Line
                InitFile = $initialization.File
                InitLine = $initialization.Line
            })
    }

    $missingArray = @($missing.ToArray() | Sort-Object File, Line, Kind, Name)
    $proofArray = @($proofs.ToArray() | Sort-Object ReadFile, ReadLine, Kind, Name)
    $uncertaintyArray = @($uncertainties.ToArray() | Sort-Object File, Line, Reason -Unique)
    $verdict = if ($missingArray.Count -gt 0) { 'FAIL' } elseif ($uncertaintyArray.Count -gt 0) { 'UNCERTAIN' } else { 'PASS' }
    $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $result = [ordered]@{
        verdict = $verdict
        path = $resolvedPath
        files = $sourceFiles.Count
        reads = $reads.Count
        inits = $initializations.Count
        missingInit = @($missingArray)
        uncertainties = @($uncertaintyArray)
        proofs = @($proofArray)
    }

    if ($Json) {
        Write-Output ($result | ConvertTo-Json -Depth 6)
    } else {
        Write-Output ('INIT-DATA-GATE ' + $verdict)
        Write-Output ('Path: ' + $resolvedPath)
        Write-Output ('Files: ' + $result.files + ' | Reads: ' + $result.reads + ' | Inits: ' + $result.inits)
        foreach ($item in $missingArray) {
            Write-Output ('MISSING-INIT: ' + $item.Kind + ' ' + $item.Name + ' ' + $item.File + ':' + $item.Line)
        }
        foreach ($item in $uncertaintyArray) {
            Write-Output ('UNCERTAINTY: ' + $item.File + ':' + $item.Line + ' ' + $item.Reason)
        }
        foreach ($item in $proofArray) {
            Write-Output ('PROOF: ' + $item.Name + ' read ' + $item.ReadFile + ':' + $item.ReadLine + ' <- init ' + $item.InitFile + ':' + $item.InitLine)
        }
    }

    if ($verdict -eq 'FAIL') { exit 1 }
    if ($verdict -eq 'UNCERTAIN') { exit 2 }
    exit 0
} catch {
    if ($Json) {
        $errorResult = [ordered]@{
            verdict = 'ERROR'
            error = $_.Exception.Message
            path = $Path
            files = 0
            reads = 0
            inits = 0
            missingInit = @()
            uncertainties = @()
            proofs = @()
        }
        Write-Output ($errorResult | ConvertTo-Json -Depth 4)
    } else {
        Write-Output ('INIT-DATA-GATE ERROR: ' + $_.Exception.Message)
    }
    exit 2
}