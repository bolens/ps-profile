#Requires -Version 7.0
<#
.SYNOPSIS
    Reorders comment-based help sections into the conventional sequence.

.DESCRIPTION
    Moves .PARAMETER, .OUTPUTS, and .NOTES sections ahead of .EXAMPLE when help
    blocks were written in the wrong order. Preserves multiple sections of the
    same type in their original relative order.
#>
param(
    [Parameter(Mandatory)]
    [string[]]$Path
)

$script:ReorderHelpSkipFileNames = @(
    'reorder-comment-help.ps1'
    'improve-bare-examples.ps1'
    'cleanup-help-examples.ps1'
    'enrich-missing-examples.ps1'
    'enrich-missing-parameters.ps1'
    'enrich-synopsis-only.ps1'
    'scan-shallow-help.ps1'
    'add-comment-help.ps1'
    'CommentHelp.psm1'
    'DocParserRegex.psm1'
    'RegexUtilities.psm1'
)

function Split-HelpSections {
    <#
    .SYNOPSIS
        Splits help inner text into structured sections.
    #>
    param(
        [string]$Inner
    )

    $sections = [System.Collections.Generic.List[object]]::new()
    $lines = $Inner -split "`r?`n"
    $index = 0

    $sectionHeaderPattern = '^\s*\.(?<sectionType>SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES)\b'

    while ($index -lt $lines.Count) {
        $line = $lines[$index]
        $headerMatch = [regex]::Match($line, $sectionHeaderPattern)
        if ($headerMatch.Success) {
            $sectionLines = [System.Collections.Generic.List[string]]::new()
            $sectionLines.Add($line) | Out-Null
            $index++

            while ($index -lt $lines.Count -and -not [regex]::IsMatch($lines[$index], $sectionHeaderPattern)) {
                $sectionLines.Add($lines[$index]) | Out-Null
                $index++
            }

            $sections.Add([PSCustomObject]@{
                    Type  = $headerMatch.Groups['sectionType'].Value
                    Lines = $sectionLines.ToArray()
                })
        }
        else {
            $index++
        }
    }

    return $sections
}

function Test-HelpNeedsReorder {
    param(
        [string]$Inner
    )

    $sections = Split-HelpSections -Inner $Inner
    $sawExample = $false
    foreach ($section in $sections) {
        if ($section.Type -eq 'EXAMPLE') {
            $sawExample = $true
            continue
        }

        if ($sawExample -and $section.Type -in @('PARAMETER', 'OUTPUTS', 'NOTES')) {
            return $true
        }
    }

    return $false
}

function Join-HelpSections {
    param(
        [System.Collections.Generic.List[object]]$Sections
    )

    $rank = @{
        SYNOPSIS    = 0
        DESCRIPTION = 1
        PARAMETER   = 2
        OUTPUTS     = 3
        NOTES       = 4
        EXAMPLE     = 5
    }

    $ordered = $Sections | Sort-Object @{ Expression = { $rank[$_.Type] } }, @{ Expression = { $Sections.IndexOf($_) } }
    $output = [System.Collections.Generic.List[string]]::new()

    foreach ($section in $ordered) {
        if ($output.Count -gt 0) {
            $output.Add('') | Out-Null
        }

        foreach ($line in $section.Lines) {
            $output.Add($line) | Out-Null
        }
    }

    return ($output -join "`n").TrimEnd()
}

function Normalize-HelpBlockInner {
    param(
        [string]$Inner
    )

    if (-not (Test-HelpNeedsReorder -Inner $Inner)) {
        return $Inner
    }

    $sections = Split-HelpSections -Inner $Inner
    return Join-HelpSections -Sections $sections
}

function Update-ReorderedHelpInFile {
    param(
        [string]$FilePath
    )

    $content = Get-Content -LiteralPath $FilePath -Raw
    $pattern = '(?ms)(?<indent>\s*)<#\s*\r?\n(?<body>.*?)\r?\n(?<indent2>\s*)#>'
    $matches = [regex]::Matches($content, $pattern)
    if ($matches.Count -eq 0) {
        return $false
    }

    $sb = [System.Text.StringBuilder]::new()
    $lastIndex = 0
    $changed = $false

    foreach ($match in $matches) {
        [void]$sb.Append($content.Substring($lastIndex, $match.Index - $lastIndex))
        $body = $match.Groups['body'].Value
        $normalized = Normalize-HelpBlockInner -Inner $body.TrimEnd()

        if ($normalized -eq $body.TrimEnd()) {
            [void]$sb.Append($match.Value)
        }
        else {
            $indent = $match.Groups['indent'].Value
            $indent2 = $match.Groups['indent2'].Value
            [void]$sb.Append("$indent<#`n$normalized`n$indent2#>")
            $changed = $true
        }

        $lastIndex = $match.Index + $match.Length
    }

    if (-not $changed) {
        return $false
    }

    [void]$sb.Append($content.Substring($lastIndex))
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
        if ($script:ReorderHelpSkipFileNames -contains $file.Name -or $file.Name -like 'Doc*.psm1') {
            continue
        }

        if (Update-ReorderedHelpInFile -FilePath $file.FullName) {
            Write-Output "Reordered: $($file.FullName)"
        }
    }
}
