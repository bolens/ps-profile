<#
scripts/utils/generate-docs.ps1

Generates API documentation from comment-based help in PowerShell functions.

Usage: pwsh -NoProfile -File scripts/utils/generate-docs.ps1
#>

param(
    [string]$OutputPath = "docs"
)

# Helper function for GetRelativePath compatibility with older .NET versions
function Get-RelativePath {
    param([string]$From, [string]$To)

    $fromUri = [Uri]::new($From)
    $toUri = [Uri]::new($To)

    if ($fromUri.Scheme -ne $toUri.Scheme) {
        return $To
    }

    $relativeUri = $fromUri.MakeRelativeUri($toUri)
    $relativePath = [Uri]::UnescapeDataString($relativeUri.ToString())

    # Convert forward slashes to backslashes on Windows
    if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
        $relativePath = $relativePath -replace '/', '\'
    }

    return $relativePath
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Handle OutputPath - if it's absolute, use it directly, otherwise join with repo root
if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $docsPath = $OutputPath
}
else {
    $docsPath = Join-Path $repoRoot $OutputPath
}

$profilePath = Join-Path $repoRoot 'profile.d'

Write-Output "Generating API documentation..."

# Create docs directory if it doesn't exist
if (-not (Test-Path $docsPath)) {
    New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
}

# Find all functions with comment-based help
$functions = @()

Get-ChildItem -Path $profilePath -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-Output "Scanning $file for functions..."

    # Parse the file content to find functions using AST
    $content = Get-Content $file -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
    $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    foreach ($funcAst in $functionAsts) {
        $functionName = $funcAst.Name

        # Skip functions with colons (like global:..) as they are internal aliases
        if ($functionName -match ':') {
            continue
        }

        $start = $funcAst.Extent.StartOffset

        # Build function signature
        $signature = $functionName
        if ($funcAst.Parameters) {
            $paramList = $funcAst.Parameters | ForEach-Object {
                $paramName = $_.Name.VariablePath.UserPath
                $paramType = if ($_.StaticType) { "[$($_.StaticType.Name)]" } else { "" }
                "$paramType`$$paramName"
            }
            if ($paramList) {
                $signature += " " + ($paramList -join ", ")
            }
        }

        # Get text before the function
        $beforeText = $content.Substring(0, $start)

        # Find the last comment block before the function
        $commentMatches = [regex]::Matches($beforeText, '<#[\s\S]*?#>')
        if ($commentMatches.Count -gt 0) {
            $helpContent = $commentMatches[-1].Value  # Last comment block
            # Remove the comment markers
            $helpContent = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
        }
        else {
            continue  # No comment block, skip
        }

        # Trim leading/trailing whitespace from help content
        $helpContent = $helpContent.Trim()

        # Remove carriage returns
        $helpContent = $helpContent -replace '\r', ''

        # Normalize indentation by removing common leading spaces
        $lines = $helpContent -split "\r?\n"
        $minIndent = ($lines | Where-Object { $_ -match '\S' } | ForEach-Object { ($_.Length - $_.TrimStart().Length) } | Measure-Object -Minimum).Minimum
        if ($minIndent -gt 0) {
            $lines = $lines | ForEach-Object { if ($_.Length -ge $minIndent) { $_.Substring($minIndent) } else { $_ } }
        }
        $helpContent = $lines -join "`n"

        # Parse the help content
        $synopsis = ""
        $description = ""
        $parameters = @()
        $examples = @()

        # Extract SYNOPSIS
        if ($helpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)\n\s*\.DESCRIPTION') {
            $synopsis = $matches[1].Trim()
        }

        # Extract DESCRIPTION
        if ($helpContent -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.|\n\s*#>|$)') {
            $description = $matches[1].Trim()
        }

        # Extract PARAMETERS
        $paramMatches = [regex]::Matches($helpContent, '(?s)\s*\.PARAMETER\s+(\w+)\s*\n\s*(.+?)(?=\n\s*\.|\n\s*#>)')
        foreach ($paramMatch in $paramMatches) {
            $parameters += [PSCustomObject]@{
                Name        = $paramMatch.Groups[1].Value
                Description = $paramMatch.Groups[2].Value.Trim()
            }
        }

        # Extract EXAMPLES
        $exampleMatches = [regex]::Matches($helpContent, '(?s)\s*\.EXAMPLE\s*\n\s*(.+?)(?=\n\s*\.|\n\s*#>)')
        foreach ($exampleMatch in $exampleMatches) {
            $examples += $exampleMatch.Groups[1].Value.Trim()
        }

        $functions += [PSCustomObject]@{
            Name        = $functionName
            Signature   = $signature
            Synopsis    = $synopsis
            Description = $description
            Parameters  = $parameters
            Examples    = $examples
            File        = $file
        }
    }
}

if ($functions.Count -eq 0) {
    Write-Output "No functions with comment-based help found."
    exit 0
}

Write-Output "Found $($functions.Count) functions with documentation."

# Generate markdown documentation
foreach ($function in $functions) {
    $mdFile = Join-Path $docsPath "$($function.Name).md"

    $content = @"
# $($function.Name)

## Synopsis

$($function.Synopsis)

## Description

$($function.Description)

## Signature

``````powershell
$($function.Signature)
``````
"@

    if ($function.Parameters.Count -gt 0) {
        $content += "`n`n## Parameters`n"
        foreach ($param in $function.Parameters) {
            $content += "`n### -$($param.Name)`n`n$($param.Description)"
        }
    }
    else {
        $content += "`n`n## Parameters`n`nNo parameters."
    }

    $content += "`n`n## Examples"

    if ($function.Examples.Count -gt 0) {
        for ($i = 0; $i -lt $function.Examples.Count; $i++) {
            $content += "`n`n### Example $($i + 1)`n`n``````powershell`n$($function.Examples[$i])`n``````"
        }
    }
    else {
        $content += "`n`nNo examples provided."
    }

    $content += "`n`n## Source`n`nDefined in: $(Get-RelativePath $docsPath $function.File)"

    $content | Out-File -FilePath $mdFile -Encoding UTF8 -NoNewline:$false
    Write-Output "Generated documentation: $mdFile"
}

# Generate index file
$groupedFunctions = $functions | Group-Object { [System.IO.Path]::GetFileName($_.File) } | Sort-Object Name

$indexContent = @"
    # PowerShell Profile API Documentation

    This documentation is automatically generated from comment-based help in the profile functions.

    **Total Functions:** $($functions.Count)
    **Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    ## Functions by Fragment

    $(foreach ($group in $groupedFunctions) {
            $fragmentName = $group.Name -replace '\.ps1$', ''
            $functionList = $group.Group | Sort-Object Name | ForEach-Object { "- [$($_.Name)]($($_.Name).md) - $($_.Synopsis)" }
            "### $fragmentName ($($group.Count) functions)`n`n$($functionList -join "`n")`n`n"
        })

    ## Generation

    This documentation was generated from the comment-based help in the profile fragments.
"@

$indexContent | Out-File -FilePath (Join-Path $docsPath 'README.md') -Encoding UTF8 -NoNewline:$false

Write-Output "`nAPI documentation generated in: $docsPath"
Write-Output "Generated documentation for $($functions.Count) functions."
