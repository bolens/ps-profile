# ===============================================
# migrate-command-detection.ps1
# Migration script to replace Test-HasCommand with Test-CachedCommand
# ===============================================

<#
.SYNOPSIS
    Migrates Test-HasCommand calls to Test-CachedCommand.

.DESCRIPTION
    Scans profile.d directory and replaces all Test-HasCommand calls
    with Test-CachedCommand for better performance and consistency.

.PARAMETER Path
    Specific file or directory to migrate. Defaults to profile.d.

.PARAMETER WhatIf
    Shows what would be changed without making changes (dry run).

.PARAMETER DryRun
    Alias for WhatIf. Shows what would be changed without making changes.

.EXAMPLE
    .\migrate-command-detection.ps1 -DryRun

    Shows all files that would be migrated (dry run).

.EXAMPLE
    .\migrate-command-detection.ps1 -WhatIf

    Shows all files that would be migrated (dry run).

.EXAMPLE
    .\migrate-command-detection.ps1

    Migrates all files in profile.d (actual migration).

.EXAMPLE
    .\migrate-command-detection.ps1 -Path profile.d\cli-modules

    Migrates only files in the cli-modules directory.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path,
    
    [Alias('DryRun')]
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'

# Resolve default path if not provided
if (-not $Path) {
    # Script is in scripts/utils/fragment/, need to go up 3 levels to repo root
    $repoRoot = $PSScriptRoot
    for ($i = 1; $i -le 3; $i++) {
        $repoRoot = Split-Path -Parent $repoRoot
    }
    $Path = Join-Path $repoRoot 'profile.d'
}

# Handle dry run mode (WhatIf is provided by SupportsShouldProcess)
$isDryRun = $Preview -or $WhatIfPreference -eq 'Continue'

if ($isDryRun) {
    Write-Host "DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Yellow
}

# Validate path
if (-not (Test-Path -Path $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

# Find all PowerShell files
$files = Get-ChildItem -Path $Path -Filter '*.ps1' -Recurse -File

if ($files.Count -eq 0) {
    Write-Warning "No PowerShell files found in: $Path"
    exit 0
}

Write-Host "`nScanning $($files.Count) PowerShell file(s)..." -ForegroundColor Cyan

$migratedCount = 0
$totalReplacements = 0
$filesToMigrate = @()

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        continue
    }
    
    $originalContent = $content
    $fileReplacements = 0

    # Count occurrences before replacement
    $occurrenceCount = ([regex]::Matches($content, 'Test-HasCommand')).Count
    if ($occurrenceCount -eq 0) {
        continue
    }

    # Pattern 1: Test-HasCommand -Name 'command'
    # Replace with: Test-CachedCommand -Name 'command'
    $content = $content -replace "Test-HasCommand\s+-Name\s+", 'Test-CachedCommand -Name '

    # Pattern 2: Test-HasCommand 'command' (positional)
    # Replace with: Test-CachedCommand 'command'
    $content = $content -replace "Test-HasCommand\s+([`"'])([^`"']+)\1", 'Test-CachedCommand $1$2$1'

    # Pattern 3: Test-HasCommand $variable
    # Replace with: Test-CachedCommand $variable
    $content = $content -replace "Test-HasCommand\s+(\$[a-zA-Z_][a-zA-Z0-9_]*)", 'Test-CachedCommand $1'

    # Pattern 4: if (Test-HasCommand 'cmd') { ... }
    # Replace with: if (Test-CachedCommand 'cmd') { ... }
    $content = $content -replace "\(Test-HasCommand\s+", '(Test-CachedCommand '

    if ($content -ne $originalContent) {
        $fileReplacements = $occurrenceCount
        $totalReplacements += $fileReplacements
        
        $relativePath = $file.FullName.Replace((Get-Item $Path).FullName, '').TrimStart('\')
        $filesToMigrate += [PSCustomObject]@{
            Path         = $relativePath
            FullPath     = $file.FullName
            Replacements = $fileReplacements
        }
    }
}

# Display results
if ($filesToMigrate.Count -eq 0) {
    Write-Host "`nNo files need migration. All files already use Test-CachedCommand." -ForegroundColor Green
    exit 0
}

Write-Host "`nFiles to migrate: $($filesToMigrate.Count)" -ForegroundColor Cyan
Write-Host "Total replacements: $totalReplacements" -ForegroundColor Cyan
Write-Host ""

foreach ($fileInfo in $filesToMigrate) {
    if ($isDryRun) {
        Write-Host "[DRY RUN] Would migrate: $($fileInfo.Path) ($($fileInfo.Replacements) replacement(s))" -ForegroundColor Yellow
    }
    else {
        if ($PSCmdlet.ShouldProcess($fileInfo.FullPath, "Migrate $($fileInfo.Replacements) Test-HasCommand call(s) to Test-CachedCommand")) {
            $content = Get-Content -Path $fileInfo.FullPath -Raw
            
            # Apply replacements
            $content = $content -replace "Test-HasCommand\s+-Name\s+", 'Test-CachedCommand -Name '
            $content = $content -replace "Test-HasCommand\s+([`"'])([^`"']+)\1", 'Test-CachedCommand $1$2$1'
            $content = $content -replace "Test-HasCommand\s+(\$[a-zA-Z_][a-zA-Z0-9_]*)", 'Test-CachedCommand $1'
            $content = $content -replace "\(Test-HasCommand\s+", '(Test-CachedCommand '
            
            Set-Content -Path $fileInfo.FullPath -Value $content -NoNewline
            Write-Host "Migrated: $($fileInfo.Path) ($($fileInfo.Replacements) replacement(s))" -ForegroundColor Green
            $migratedCount++
        }
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "Migration Summary:" -ForegroundColor Cyan
if ($isDryRun) {
    Write-Host "  Mode: DRY RUN (no files modified)" -ForegroundColor Yellow
    Write-Host "  Files that would be migrated: $($filesToMigrate.Count)" -ForegroundColor White
}
else {
    Write-Host "  Mode: ACTUAL MIGRATION" -ForegroundColor Green
    Write-Host "  Files migrated: $migratedCount" -ForegroundColor White
}
Write-Host "  Total replacements: $totalReplacements" -ForegroundColor White
Write-Host ""

if ($isDryRun) {
    Write-Host "To perform the actual migration, run without -Preview, -DryRun, or -WhatIf" -ForegroundColor Yellow
}

