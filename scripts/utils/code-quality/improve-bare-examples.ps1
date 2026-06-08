#Requires -Version 7.0
<#
.SYNOPSIS
    Replaces bare .EXAMPLE lines with parameter-aware invocation examples.

.DESCRIPTION
    Scans function help blocks and upgrades examples that only list the function
    name to include mandatory parameters inferred from the function AST.
#>
param(
    [Parameter(Mandatory)]
    [string[]]$Path
)

$script:BareExampleSkipFileNames = @(
    'improve-bare-examples.ps1'
    'enrich-missing-examples.ps1'
    'enrich-missing-parameters.ps1'
    'enrich-synopsis-only.ps1'
    'scan-shallow-help.ps1'
    'add-comment-help.ps1'
    'CommentHelp.psm1'
    'DocParserRegex.psm1'
    'RegexUtilities.psm1'
    'cleanup-help-examples.ps1'
    'reorder-comment-help.ps1'
)

function Get-ExampleValueForParameter {
    param(
        [string]$Name,
        [string]$TypeName
    )

    switch ($Name) {
        'FilePath' { return './Taskfile.yml' }
        'Path' { return './path' }
        'WatchPath' { return '(Get-Location).Path' }
        'Command' { return "'pwsh -NoProfile -File scripts/test.ps1'" }
        'Content' { return "'text'" }
        'Label' { return "'test'" }
        'Token' { return "'{{.CLI_ARGS}}'" }
        'Text' { return "'scripts/utils/test.ps1'" }
        'Lines' { return "@('pwsh -File scripts/test.ps1')" }
        'Tasks' { return '$tasks' }
        'ReferenceTasks' { return '$refTasks' }
        'FileType' { return "'taskfile'" }
        'From' { return "'C:/src'" }
        'To' { return "'C:/src/docs'" }
        'Message' { return "'message'" }
        'Functions' { return '$functions' }
        'Aliases' { return '$aliases' }
        'DocsPath' { return "'docs/api'" }
        'DocumentedCommandNames' { return '$documented' }
        'OnlyNames' { return '$onlyNames' }
        'CodeMetrics' { return '$codeMetrics' }
        'PerformanceMetrics' { return '$perfMetrics' }
        'CoverageTrends' { return '$coverageTrends' }
        'HistoricalData' { return '$historical' }
        'SecurityRules' { return '$rules' }
        'ExternalCommandPatterns' { return '$ext' }
        'SecretPatterns' { return '$secrets' }
        'FalsePositivePatterns' { return '@()' }
        'Allowlist' { return '@{}' }
        'GuideFile' { return "'docs/guides/TESTING.md'" }
        'TestPaths' { return "@('tests/unit')" }
        'Config' { return '$config' }
        'ScriptBlock' { return '{ }' }
        'ExecutionScriptBlock' { return '$sb' }
        'Exception' { return '$err' }
        'InputObject' { return '$data' }
        'JsonString' { return "'{}'" }
        'Package' { return "'ruff'" }
        'Arguments' { return "@('--help')" }
        'Args' { return "@('--version')" }
        'Bin' { return "'tool'" }
        'ToolName' { return "'docker'" }
        'InputPath' { return './input.file' }
        'OutputPath' { return './output.file' }
        'Name' { return "'name'" }
        'Value' { return "'value'" }
        'Url' { return "'https://example.com'" }
        'Query' { return "'search term'" }
        'Branch' { return "'main'" }
        'Repository' { return "'owner/repo'" }
        'ModuleName' { return "'Pester'" }
        'FragmentName' { return "'git.ps1'" }
        'CommandName' { return "'Get-GitStatus'" }
        'Source' { return './source' }
        'Destination' { return './destination' }
        'Pattern' { return "'search-term'" }
        'Suite' { return "'Unit'" }
        'TestFile' { return "'tests/unit/example.tests.ps1'" }
        'TestRunnerScriptPath' { return "'scripts/utils/code-quality/run-pester.ps1'" }
        'Packages' { return "'package-name'" }
        'Script' { return "'build'" }
        'KebabName' { return "'example-name'" }
        'Candidate' { return "'profile.d/git.ps1'" }
        'TestRelativePath' { return "'tests/unit/example.tests.ps1'" }
        'TestFileBaseName' { return "'library-example'" }
        'LibraryTestFiles' { return '$libraryTestFiles' }
        'Key' { return "'key'" }
        'Title' { return "'title'" }
        'Version' { return "'1.0.0'" }
        default {
            if ($TypeName -match 'hashtable|Hashtable') { return '@{}' }
            if ($TypeName -match '\[\]') { return '@()' }
            if ($TypeName -match 'bool|Boolean|Switch') { return '' }
            if ($TypeName -match 'int|Int') { return '1' }
            return "'value'"
        }
    }
}

function Test-OptionalExampleParameter {
    param(
        [string]$Name
    )

    return $Name -notmatch '^(Force|Verbose|Debug|WhatIf|Confirm|PassThru|ErrorAction|WarningAction|PipelineVariable|IncludeHistorical|DryRun|Refresh|Incremental)$'
}

function Get-FunctionExampleLine {
    param(
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst
    )

    $funcName = $FuncAst.Name -replace '^.*:', ''
    if (-not $FuncAst.Body.ParamBlock) {
        return "    $funcName"
    }

    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $FuncAst.Body.ParamBlock.Parameters) {
        $isMandatory = $false
        foreach ($attr in $p.Attributes) {
            if ($attr.TypeName.Name -eq 'Parameter') {
                foreach ($na in $attr.NamedArguments) {
                    if ($na.ArgumentName -eq 'Mandatory' -and $na.Argument.Value) {
                        $isMandatory = $true
                    }
                }
            }
        }

        if (-not $isMandatory) {
            continue
        }

        $name = $p.Name.VariablePath.UserPath
        $typeName = if ($p.StaticType) { $p.StaticType.Name } else { 'object' }
        $val = Get-ExampleValueForParameter -Name $name -TypeName $typeName
        if ([string]::IsNullOrWhiteSpace($val)) {
            $parts.Add("-$name") | Out-Null
        }
        else {
            $parts.Add("-$name $val") | Out-Null
        }
    }

    if ($parts.Count -eq 0 -and $FuncAst.Body.ParamBlock) {
        $optionalAdded = 0
        foreach ($p in $FuncAst.Body.ParamBlock.Parameters) {
            if ($optionalAdded -ge 2) {
                break
            }

            $name = $p.Name.VariablePath.UserPath
            if ($name -in @('Arguments', 'Args')) {
                continue
            }

            if (-not (Test-OptionalExampleParameter -Name $name)) {
                continue
            }

            $typeName = if ($p.StaticType) { $p.StaticType.Name } else { 'object' }
            if ($typeName -match 'switch|Switch') {
                continue
            }

            $val = Get-ExampleValueForParameter -Name $name -TypeName $typeName
            if ([string]::IsNullOrWhiteSpace($val)) {
                $parts.Add("-$name") | Out-Null
            }
            else {
                $parts.Add("-$name $val") | Out-Null
            }

            $optionalAdded++
        }
    }

    if ($parts.Count -eq 0 -and $FuncAst.Body.ParamBlock) {
        foreach ($p in $FuncAst.Body.ParamBlock.Parameters) {
            $paramName = $p.Name.VariablePath.UserPath
            if ($paramName -ne 'Arguments' -and $paramName -ne 'Args') {
                continue
            }

            if ($funcName -match '^Invoke-') {
                return ('    {0} @(''--help'')' -f $funcName)
            }

            return "    $funcName"
        }
    }

    if ($parts.Count -eq 0) {
        if ($funcName -match '^Find-|^Search-') {
            return ('    {0} -Pattern ''search-term''' -f $funcName)
        }
        if ($funcName -match '^Write-') {
            return ('    {0} -Message ''message''' -f $funcName)
        }
        if ($funcName -match '^Test-') {
            return "    $funcName"
        }
        if ($funcName -match '^Invoke-') {
            return ('    {0} @(''--help'')' -f $funcName)
        }
        if ($funcName -match '^Install-') {
            return ('    {0} ''package-name''' -f $funcName)
        }
        if ($funcName -match '^Set-') {
            return ('    {0} -Name ''name'' -Value ''value''' -f $funcName)
        }
        if ($funcName -match '^Add-|^Remove-') {
            return ('    {0} ''item''' -f $funcName)
        }
        if ($funcName -match '^Convert-') {
            return ('    {0} -InputObject $data' -f $funcName)
        }

        return "    $funcName"
    }

    return "    $funcName $($parts -join ' ')"
}

function Update-BareExamplesInFile {
    param(
        [string]$FilePath
    )

    $content = Get-Content -LiteralPath $FilePath -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)
    $replacements = [System.Collections.Generic.List[object]]::new()

    foreach ($funcAst in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
        $funcName = $funcAst.Name -replace '^.*:', ''
        $exampleLine = Get-FunctionExampleLine -FuncAst $funcAst
        $help = $null
        $helpStart = 0
        $helpEnd = 0

        $bodyText = $content.Substring($funcAst.Body.Extent.StartOffset, $funcAst.Body.Extent.EndOffset - $funcAst.Body.Extent.StartOffset)
        $bodyMatch = [regex]::Match($bodyText, '<#[\s\S]*?#>')
        if ($bodyMatch.Success) {
            $helpStart = $funcAst.Body.Extent.StartOffset + $bodyMatch.Index
            $helpEnd = $helpStart + $bodyMatch.Length
            $help = $bodyMatch.Value
        }
        else {
            $before = $content.Substring(0, $funcAst.Extent.StartOffset)
            $beforeMatches = [regex]::Matches($before, '<#[\s\S]*?#>')
            if ($beforeMatches.Count -eq 0) {
                continue
            }

            $last = $beforeMatches[$beforeMatches.Count - 1]
            $helpStart = $last.Index
            $helpEnd = $helpStart + $last.Length
            $help = $last.Value
        }

        $inner = ($help -replace '^<#\s*', '' -replace '\s*#>$', '').Trim()
        if ($inner -notmatch '(?m)^\s*\.EXAMPLE\s*$') {
            continue
        }

        $escapedName = [regex]::Escape($funcName)
        $indentedExample = if ($exampleLine.StartsWith('    ')) { $exampleLine } else { "    $($exampleLine.TrimStart())" }
        if ($inner -notmatch "(?m)^\s*\.EXAMPLE\s*\r?\n\s*$escapedName\s*$") {
            continue
        }

        $newInner = [regex]::Replace(
            $inner,
            "(?m)^(\s*\.EXAMPLE\s*\r?\n)\s*$escapedName\s*$",
            "`${1}$indentedExample"
        )

        $replacements.Add([PSCustomObject]@{
                Start = $helpStart
                End   = $helpEnd
                Text  = "<#`n$newInner`n#>"
            })
    }

    if ($replacements.Count -eq 0) {
        return $false
    }

    $sb = [System.Text.StringBuilder]::new()
    $ordered = $replacements | Sort-Object Start -Descending
    $cursor = $content.Length
    foreach ($r in $ordered) {
        [void]$sb.Insert(0, $content.Substring($r.End, $cursor - $r.End))
        [void]$sb.Insert(0, $r.Text)
        $cursor = $r.Start
    }

    [void]$sb.Insert(0, $content.Substring(0, $cursor))
    Set-Content -LiteralPath $FilePath -Value $sb.ToString() -NoNewline -Encoding UTF8
    return $true
}

foreach ($targetPath in $Path) {
    if (-not (Test-Path -LiteralPath $targetPath)) {
        continue
    }

    $files = if ((Get-Item -LiteralPath $targetPath).PSIsContainer) {
        Get-ChildItem -Path $targetPath -Recurse -Include '*.ps1', '*.psm1' -File
    }
    else {
        , (Get-Item -LiteralPath $targetPath)
    }

    foreach ($file in $files) {
        if ($script:BareExampleSkipFileNames -contains $file.Name -or $file.Name -like 'Doc*.psm1') {
            continue
        }

        if (Update-BareExamplesInFile -FilePath $file.FullName) {
            Write-Output "Updated: $($file.FullName)"
        }
    }
}
