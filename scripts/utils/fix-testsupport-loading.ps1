# ================================================
# fix-testsupport-loading.ps1
# Fixes TestSupport.ps1 loading pattern in test files
# ================================================

<#
.SYNOPSIS
    Fixes TestSupport.ps1 loading pattern in test files.

.DESCRIPTION
    Updates test files to use a robust TestSupport.ps1 loading pattern that works
    from any subdirectory depth. Can run in dry-run mode to preview changes.

.PARAMETER TestPath
    Specific test file or directory to fix. Defaults to all test files.

.PARAMETER DryRun
    Preview changes without modifying files.

.PARAMETER WhatIf
    Alias for DryRun - preview changes without modifying files.

.EXAMPLE
    .\fix-testsupport-loading.ps1 -DryRun

    Preview all changes that would be made.

.EXAMPLE
    .\fix-testsupport-loading.ps1 -TestPath tests/integration/conversion -DryRun

    Preview changes for conversion tests only.

.EXAMPLE
    .\fix-testsupport-loading.ps1

    Apply fixes to all test files.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$TestPath = 'tests',

    [Parameter()]
    [switch]$DryRun
)

# Use -WhatIf if DryRun is provided
if ($DryRun) {
    $WhatIfPreference = $true
}
else {
    $WhatIfPreference = $false
}

# Robust TestSupport.ps1 loading pattern
$newPattern = @'
# Resolve TestSupport.ps1 path (works from any subdirectory depth)
$current = $null
if ($PSScriptRoot) {
    # Pester sets $PSScriptRoot to the test file path, so get the directory
    $scriptDir = Split-Path -Parent $PSScriptRoot -ErrorAction SilentlyContinue
    if (-not $scriptDir) {
        # If Split-Path fails, try using $PSScriptRoot as-is (might already be a directory)
        $scriptDir = $PSScriptRoot
    }
    if ($scriptDir -and (Test-Path $scriptDir)) {
        $current = Get-Item $scriptDir -ErrorAction SilentlyContinue
    }
}
while ($null -ne $current) {
    $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
    if (Test-Path $testSupportPath) {
        . $testSupportPath
        break
    }
    if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
    $current = $current.Parent
}
'@

# Patterns to replace
$oldPatterns = @(
    # Old relative path pattern
    @{
        Pattern     = '\. \(Join-Path \$PSScriptRoot.*TestSupport\.ps1\)'
        Description = 'Old relative path pattern'
    },
    # Missing error handling
    @{
        Pattern     = 'Get-Item \$PSScriptRoot\s+while'
        Description = 'Missing error handling in Get-Item'
    }
)

function Test-FileNeedsFix {
    param(
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        return $false
    }

    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return $false
    }

    # Check if file already has the correct pattern (with Split-Path)
    if ($content -match 'Split-Path -Parent \$PSScriptRoot') {
        return $false
    }

    # Check if file needs TestSupport loading (has test structure)
    if ($content -match 'Describe\s+[''"]|Context\s+[''"]|It\s+[''"]') {
        # Check if it's missing TestSupport loading entirely
        if ($content -notmatch 'TestSupport\.ps1' -and $content -notmatch 'Get-TestPath' -and $content -notmatch 'Get-TestRepoRoot') {
            # Might be a unit test that doesn't need it, skip
            return $false
        }

        # Check if it has old pattern or missing Split-Path fix
        if ($content -match '\. \(Join-Path \$PSScriptRoot.*TestSupport\.ps1\)' -or
            ($content -match 'Resolve TestSupport\.ps1 path' -and $content -notmatch 'Split-Path -Parent \$PSScriptRoot') -or
            ($content -match 'Get-Item \$PSScriptRoot' -and $content -notmatch 'Split-Path -Parent \$PSScriptRoot')) {
            return $true
        }
    }

    return $false
}

function Get-FixAction {
    param(
        [string]$FilePath
    )

    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        return $null
    }

    $action = @{
        File           = $FilePath
        NeedsFix       = $false
        CurrentPattern = $null
        NewPattern     = $null
        LineNumbers    = @()
    }

    # Check for old relative path pattern
    if ($content -match '\. \(Join-Path \$PSScriptRoot.*TestSupport\.ps1\)') {
        $action.NeedsFix = $true
        $action.CurrentPattern = 'Old relative path pattern'
        $action.NewPattern = 'Robust resolver pattern with error handling'
        
        # Find line numbers
        $lines = Get-Content $FilePath
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '\. \(Join-Path.*TestSupport\.ps1\)') {
                $action.LineNumbers += ($i + 1)
            }
        }
        return $action
    }

    # Check for missing Split-Path fix (most common - Pester sets $PSScriptRoot to file path, not directory)
    if ($content -match 'Resolve TestSupport\.ps1 path' -and 
        $content -notmatch 'Split-Path -Parent \$PSScriptRoot') {
        $action.NeedsFix = $true
        $action.CurrentPattern = 'Resolver pattern without Split-Path fix'
        $action.NewPattern = 'Add Split-Path to handle Pester file path behavior'
        
        # Find line numbers
        $lines = Get-Content $FilePath
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'Resolve TestSupport\.ps1 path') {
                $action.LineNumbers += ($i + 1)
            }
        }
        return $action
    }

    # Check for missing error handling (legacy check)
    if ($content -match 'Resolve TestSupport\.ps1 path' -and 
        $content -match 'Get-Item \$PSScriptRoot' -and
        $content -notmatch 'Get-Item \$PSScriptRoot -ErrorAction') {
        $action.NeedsFix = $true
        $action.CurrentPattern = 'Resolver pattern without error handling'
        $action.NewPattern = 'Add error handling to Get-Item'
        
        # Find line numbers
        $lines = Get-Content $FilePath
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'Get-Item \$PSScriptRoot' -and $lines[$i] -notmatch 'ErrorAction') {
                $action.LineNumbers += ($i + 1)
            }
        }
        return $action
    }

    return $null
}

function Apply-Fix {
    param(
        [string]$FilePath
    )

    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Warning "Could not read file: $FilePath"
        return $false
    }

    $modified = $false

    # Replace old relative path pattern
    if ($content -match '\. \(Join-Path \$PSScriptRoot.*TestSupport\.ps1\)') {
        # Find the old pattern and replace with new one
        $oldPatternMatch = [regex]::Match($content, '\. \(Join-Path \$PSScriptRoot[^\)]+TestSupport\.ps1\)')
        if ($oldPatternMatch.Success) {
            # Check if there's already a resolver pattern comment
            if ($content -notmatch 'Resolve TestSupport\.ps1 path') {
                $content = $content -replace [regex]::Escape($oldPatternMatch.Value), $newPattern
                $modified = $true
            }
            else {
                # Just remove the old pattern
                $content = $content -replace [regex]::Escape($oldPatternMatch.Value), ''
                $modified = $true
            }
        }
    }

    # Replace existing resolver pattern with more robust version (with Split-Path)
    if ($content -match 'Resolve TestSupport\.ps1 path') {
        # Check if it already has the robust pattern (with Split-Path)
        if ($content -notmatch 'Split-Path -Parent \$PSScriptRoot') {
            # Find and replace the old resolver block
            # Match from "# Resolve" comment through the closing brace of the while loop
            # This regex matches the entire resolver block including the while loop
            # Pattern: comment, then $current = Get-Item $PSScriptRoot, then while loop with closing brace
            $oldResolverPattern = '(?s)# Resolve TestSupport\.ps1 path.*?\r?\n\$current = Get-Item \$PSScriptRoot[^\r\n]*\r?\nwhile[^}]*\}'
            if ($content -match $oldResolverPattern) {
                $match = [regex]::Match($content, $oldResolverPattern)
                if ($match.Success) {
                    $content = $content -replace [regex]::Escape($match.Value), $newPattern
                    $modified = $true
                }
            }
        }
    }

    if ($modified) {
        # Clean up extra blank lines
        $content = $content -replace "`r?`n`r?`n`r?`n+", "`r`n`r`n"
        
        Set-Content -Path $FilePath -Value $content -NoNewline
        return $true
    }

    return $false
}

# Main execution
Write-Host "TestSupport.ps1 Loading Pattern Fix Script" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    Write-Host ""
}

# Find test files
$testFiles = @()
if (Test-Path $TestPath) {
    if ((Get-Item $TestPath) -is [System.IO.DirectoryInfo]) {
        $testFiles = Get-ChildItem -Path $TestPath -Filter '*.tests.ps1' -Recurse -File
    }
    else {
        $testFiles = @(Get-Item $TestPath)
    }
}
else {
    Write-Warning "Path not found: $TestPath"
    exit 1
}

Write-Host "Found $($testFiles.Count) test file(s)" -ForegroundColor Green
Write-Host ""

# Analyze files
$filesNeedingFix = @()
$fixActions = @()

foreach ($file in $testFiles) {
    if (Test-FileNeedsFix -FilePath $file.FullName) {
        $action = Get-FixAction -FilePath $file.FullName
        if ($action) {
            $filesNeedingFix += $file
            $fixActions += $action
        }
    }
}

Write-Host "Files needing fixes: $($filesNeedingFix.Count)" -ForegroundColor $(if ($filesNeedingFix.Count -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ""

if ($filesNeedingFix.Count -eq 0) {
    Write-Host "No files need fixing!" -ForegroundColor Green
    exit 0
}

# Show preview
Write-Host "Files that will be modified:" -ForegroundColor Cyan
Write-Host ""

$count = 0
foreach ($action in $fixActions) {
    $count++
    Write-Host "[$count/$($fixActions.Count)] $($action.File)" -ForegroundColor White
    Write-Host "  Current: $($action.CurrentPattern)" -ForegroundColor Gray
    Write-Host "  Change:  $($action.NewPattern)" -ForegroundColor Gray
    if ($action.LineNumbers.Count -gt 0) {
        Write-Host "  Lines:   $($action.LineNumbers -join ', ')" -ForegroundColor Gray
    }
    Write-Host ""
}

if ($DryRun) {
    Write-Host "DRY RUN COMPLETE - No files were modified" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
    exit 0
}

# Apply fixes
Write-Host "Applying fixes..." -ForegroundColor Cyan
Write-Host ""

$fixed = 0
$failed = 0

foreach ($file in $filesNeedingFix) {
    if ($DryRun) {
        # In dry-run, we already showed what would be changed
        continue
    }
    
    if ($PSCmdlet.ShouldProcess($file.FullName, "Fix TestSupport loading pattern")) {
        try {
            if (Apply-Fix -FilePath $file.FullName) {
                Write-Host "✓ Fixed: $($file.FullName)" -ForegroundColor Green
                $fixed++
            }
            else {
                Write-Host "⊘ No changes needed: $($file.FullName)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "✗ Failed: $($file.FullName) - $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Files fixed:   $fixed" -ForegroundColor Green
Write-Host "  Files failed:  $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Total:         $($filesNeedingFix.Count)" -ForegroundColor White

if ($failed -gt 0) {
    exit 1
}

exit 0

