#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Fixes multiple consecutive blank lines in markdown files.

.DESCRIPTION
    Replaces multiple consecutive blank lines with a single blank line in all markdown files.
#>

$ErrorActionPreference = 'Stop'

$markdownFiles = Get-ChildItem -Path . -Include *.md -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\node_modules\\' -and
    $_.FullName -notmatch '\\Modules\\'
}

$fixedCount = 0

foreach ($file in $markdownFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    
    # Replace 3+ consecutive newlines with 2 newlines (one blank line)
    $content = $content -replace "(\r?\n){3,}", "`r`n`r`n"
    
    # Replace 2+ consecutive newlines at the end with 1 newline
    $content = $content -replace "(\r?\n){2,}$", "`r`n"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $fixedCount++
        Write-Host "Fixed: $($file.FullName)" -ForegroundColor Green
    }
}

Write-Host "Fixed $fixedCount markdown files" -ForegroundColor Cyan

