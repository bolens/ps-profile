<#
scripts/utils/generate-docs.ps1

Generates API documentation from comment-based help in PowerShell functions.

Usage: pwsh -NoProfile -File scripts/utils/generate-docs.ps1
#>

param(
    [string]$OutputPath = "docs"
)

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$docsPath = Join-Path $repoRoot $OutputPath
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

    # Parse the file content to find functions
    $content = Get-Content $file -Raw

    # Simple regex to find function definitions and their help
    $functionMatches = [regex]::Matches($content, '(?s)<#(.*?)#>.*?function\s+([\w-]+)')

    foreach ($match in $functionMatches) {
        $helpContent = $match.Groups[1].Value
        $functionName = $match.Groups[2].Value

        # Parse the help content
        $synopsis = ""
        $description = ""
        $parameters = @()
        $examples = @()

        # Extract SYNOPSIS
        if ($helpContent -match '\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.)') {
            $synopsis = $matches[1].Trim()
        }

        # Extract DESCRIPTION
        if ($helpContent -match '\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.)') {
            $description = $matches[1].Trim()
        }

        # Extract PARAMETERS
        $paramMatches = [regex]::Matches($helpContent, '\.PARAMETER\s+(\w+)\s*\n\s*(.+?)(?=\n\s*\.)')
        foreach ($paramMatch in $paramMatches) {
            $parameters += [PSCustomObject]@{
                Name        = $paramMatch.Groups[1].Value
                Description = $paramMatch.Groups[2].Value.Trim()
            }
        }

        # Extract EXAMPLES
        $exampleMatches = [regex]::Matches($helpContent, '\.EXAMPLE\s*\n\s*(.+?)(?=\n\s*\.)')
        foreach ($exampleMatch in $exampleMatches) {
            $examples += $exampleMatch.Groups[1].Value.Trim()
        }

        $functions += [PSCustomObject]@{
            Name        = $functionName
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

## Parameters
"@

    if ($function.Parameters.Count -gt 0) {
        foreach ($param in $function.Parameters) {
            $content += @"

### -$($param.Name)

$($param.Description)
"@
        }
    }
    else {
        $content += "`nNo parameters."
    }

    $content += @"

## Examples
"@

    if ($function.Examples.Count -gt 0) {
        for ($i = 0; $i - $function.Examples.Count; $i++) {
            $content += @"

### Example $($i + 1)

``````powershell
$($function.Examples[$i])
``````
"@
        }
    }
    else {
        $content += "`nNo examples provided."
    }

    $content | Out-File -FilePath $mdFile -Encoding UTF8
    Write-Output "Generated documentation: $mdFile"
}

# Generate index file
$indexContent = @"
# PowerShell Profile API Documentation

This documentation is automatically generated from comment-based help in the profile functions.

## Functions

$(($functions | Sort-Object Name | ForEach-Object { "- [$($_.Name)]($($_.Name).md) - $($_.Synopsis)" }) -join "`n")

## Generation

This documentation was generated from the comment-based help in the profile fragments.
"@

$indexContent | Out-File -FilePath (Join-Path $docsPath 'README.md') -Encoding UTF8

Write-Output "`nAPI documentation generated in: $docsPath"
Write-Output "Generated documentation for $($functions.Count) functions."
