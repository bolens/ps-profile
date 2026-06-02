#Requires -Version 7.0
<#
.SYNOPSIS
    Migrates conversion integration tests to Initialize-ConversionIntegrationForTestFile.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepoRoot = (git -C (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) rev-parse --show-toplevel 2>$null),
    [switch]$WhatIfOnly
)

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

$conversionTestRoot = Join-Path $RepoRoot 'tests' 'integration' 'conversion'
$files = Get-ChildItem -Path $conversionTestRoot -Filter '*.tests.ps1' -Recurse -File

$oldPatterns = @(
    "Initialize-TestProfile -ProfileDir `$script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion"
    "Initialize-TestProfile -ProfileDir `$script:ProfileDir -LoadBootstrap -LoadConversionModules 'Specialized' -LoadFilesFragment -EnsureFileConversion"
    "Initialize-TestProfile -ProfileDir `$script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia"
    "Initialize-TestProfile -ProfileDir `$script:ProfileDir -LoadBootstrap -LoadConversionModules 'All' -LoadFilesFragment -EnsureFileConversion -EnsureFileConversionDocuments"
    "Initialize-TestProfile -ProfileDir `$script:ProfileDir -LoadBootstrap -LoadConversionModules 'All' -LoadFilesFragment -EnsureFileConversionDocuments -EnsureFileConversionMedia"
)

$replacement = 'Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir'
$skipFiles = @(
    'yaml-json.tests.ps1'
    'html.tests.ps1'
    'markdown.tests.ps1'
    'epub.tests.ps1'
)

$changed = 0
foreach ($file in $files) {
    if ($skipFiles -contains $file.Name) {
        continue
    }

    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -notmatch 'Initialize-TestProfile.*LoadConversionModules') {
        continue
    }
    if ($content -match 'Initialize-ConversionIntegration') {
        continue
    }

    $newContent = $content
    foreach ($pattern in $oldPatterns) {
        $newContent = $newContent -replace [regex]::Escape($pattern), $replacement
    }

    if ($newContent -eq $content) {
        Write-Warning "No replacement for: $($file.FullName)"
        continue
    }

    if ($WhatIfOnly) {
        Write-Host "Would update: $($file.FullName)"
    }
    else {
        Set-Content -LiteralPath $file.FullName -Value $newContent -NoNewline
        Write-Host "Updated: $($file.FullName)"
    }
    $changed++
}

Write-Host "Migration complete. Files changed: $changed"
