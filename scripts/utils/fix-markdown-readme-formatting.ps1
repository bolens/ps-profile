#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Fixes markdown formatting issues in profile.d README files.

.DESCRIPTION
    Adds blank lines around headings (MD022) and lists (MD032) in profile.d README files.
#>

$ErrorActionPreference = 'Stop'

$readmeFiles = Get-ChildItem -Path profile.d -Filter *.README.md -File

$fixedCount = 0

foreach ($file in $readmeFiles) {
    $lines = Get-Content -Path $file.FullName
    $newLines = @()
    $i = 0
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $nextLine = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { $null }
        $prevLine = if ($i -gt 0) { $newLines[-1] } else { $null }
        
        # Check if next line is a heading underline (=== or ---)
        $isUnderlinedHeading = $nextLine -and ($nextLine -match '^={3,}$' -or $nextLine -match '^-{3,}$')
        
        # Check if current line is a heading underline
        $isHeadingUnderline = $line -match '^={3,}$' -or $line -match '^-{3,}$'
        
        # Check if current line is a markdown heading (starts with #)
        $isMarkdownHeading = $line -match '^#+\s'
        
        # Check if current line starts a list
        $isListStart = $line -match '^[-*+]\s' -or $line -match '^\d+\.\s'
        
        # Check if previous line was blank
        $prevWasBlank = -not $prevLine -or $prevLine -eq ''
        
        # Check if previous line was a heading (either markdown or underlined)
        $prevWasHeading = $false
        if ($i -gt 0) {
            $prevWasHeading = $newLines[-1] -match '^#+\s' -or 
            ($i -gt 1 -and ($newLines[-2] -match '^={3,}$' -or $newLines[-2] -match '^-{3,}$'))
        }
        
        # If this is the start of an underlined heading, ensure blank line before
        if ($isUnderlinedHeading -and -not $prevWasBlank -and $i -gt 0) {
            $newLines += ''
        }
        
        # Add the current line
        $newLines += $line
        
        # If this is a heading underline, check if we need a blank line after
        if ($isHeadingUnderline) {
            $lineAfterUnderline = if ($i + 1 -lt $lines.Count) { $lines[$i + 1] } else { $null }
            if ($lineAfterUnderline -and $lineAfterUnderline -ne '' -and -not ($lineAfterUnderline -match '^[-*+]\s' -or $lineAfterUnderline -match '^\d+\.\s')) {
                $newLines += ''
            }
        }
        
        # If this is a markdown heading, check if we need a blank line after
        if ($isMarkdownHeading) {
            if ($nextLine -and $nextLine -ne '' -and -not ($nextLine -match '^#+\s' -or $nextLine -match '^={3,}$' -or $nextLine -match '^-{3,}$' -or $nextLine -match '^[-*+]\s' -or $nextLine -match '^\d+\.\s')) {
                $newLines += ''
            }
        }
        
        # Add blank line before list if previous line was heading or non-blank non-list
        if ($isListStart -and -not $prevWasBlank -and -not ($prevLine -match '^[-*+]\s' -or $prevLine -match '^\d+\.\s')) {
            # Check if previous was a heading
            if ($prevWasHeading -or ($i -gt 0 -and ($newLines[-2] -match '^#+\s' -or ($i -gt 1 -and ($newLines[-3] -match '^={3,}$' -or $newLines[-3] -match '^-{3,}$'))))) {
                # Blank line already added after heading, skip
            }
            else {
                # Insert blank line before current line (list)
                $newLines = $newLines[0..($newLines.Count - 2)] + '' + $line
            }
        }
        
        $i++
    }
    
    # Remove trailing blank lines
    while ($newLines.Count -gt 0 -and $newLines[-1] -eq '') {
        $newLines = $newLines[0..($newLines.Count - 2)]
    }
    
    $newContent = ($newLines -join "`r`n") + "`r`n"
    $originalContent = (Get-Content -Path $file.FullName -Raw)
    
    if ($newContent -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        $fixedCount++
        Write-Host "Fixed: $($file.FullName)" -ForegroundColor Green
    }
}

Write-Host "Fixed $fixedCount README files" -ForegroundColor Cyan
