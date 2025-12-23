# ===============================================
# migrate-fragment-naming.ps1
# Migration script to convert numbered fragments to named fragments
# ===============================================

<#
.SYNOPSIS
    Migrates numbered fragments (e.g., 00-bootstrap.ps1) to named fragments (e.g., bootstrap.ps1) with explicit dependencies and tier declarations.

.DESCRIPTION
    Converts numbered fragment files to named fragments by:
    1. Removing numeric prefixes from filenames
    2. Adding explicit tier declarations (# Tier: core|essential|standard|optional)
    3. Adding dependency declarations (# Dependencies: fragment1, fragment2)
    4. Preserving all existing content
    5. Updating references in other files (optional)

.PARAMETER Path
    Specific file or directory to migrate. Defaults to profile.d.

.PARAMETER Preview
    Shows what would be changed without making changes (dry run).

.PARAMETER Fragment
    Specific fragment to migrate (e.g., '01-env' or '01-env.ps1'). If not specified, migrates all fragments.

.PARAMETER UpdateReferences
    If specified, updates references to migrated fragments in other files.

.EXAMPLE
    .\migrate-fragment-naming.ps1 -Preview

    Shows all fragments that would be migrated (dry run).

.EXAMPLE
    .\migrate-fragment-naming.ps1 -Fragment '01-env'

    Migrates only the 01-env.ps1 fragment.

.EXAMPLE
    .\migrate-fragment-naming.ps1

    Migrates all fragments in profile.d (actual migration).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path,
    
    [Alias('DryRun')]
    [switch]$Preview,
    
    [string]$Fragment,
    
    [switch]$UpdateReferences
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

# Handle dry run mode
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

# Fragment tier mapping based on numeric prefixes
function Get-FragmentTierFromNumber {
    param([string]$BaseName)
    
    if ($BaseName -match '^(\d+)-') {
        $prefix = [int]$matches[1]
        
        # 00 is core (bootstrap)
        if ($prefix -eq 0) {
            return 'core'
        }
        # 01-09 are essential (env, files, utilities, etc.)
        elseif ($prefix -ge 1 -and $prefix -le 9) {
            return 'essential'
        }
        # 10-29 are essential (git, psreadline, containers, etc.)
        elseif ($prefix -ge 10 -and $prefix -le 29) {
            return 'essential'
        }
        # 30-69 are standard (language modules, cloud tools, dev tools)
        elseif ($prefix -ge 30 -and $prefix -le 69) {
            return 'standard'
        }
        # 70-99 are optional (advanced features, specialized tools)
        elseif ($prefix -ge 70 -and $prefix -le 99) {
            return 'optional'
        }
    }
    
    return 'optional' # Default
}

# Dependency mapping based on load order and common patterns
function Get-FragmentDependencies {
    param([string]$BaseName)
    
    $dependencies = @()
    
    # Bootstrap has no dependencies
    if ($BaseName -eq '00-bootstrap' -or $BaseName -eq 'bootstrap') {
        return $dependencies
    }
    
    # Core fragments (01-09) depend on bootstrap
    # Note: 01-env has been migrated to 'env', so fragments 02-09 also depend on env
    if ($BaseName -match '^0[1-9]-') {
        $dependencies += 'bootstrap'
        # Fragments after 01-env (02-09) also depend on env
        if ($BaseName -match '^0[2-9]-') {
            $dependencies += 'env'
        }
    }
    
    # Essential fragments (10-29) typically depend on bootstrap and env
    if ($BaseName -match '^(1[0-9]|2[0-9])-') {
        $dependencies += 'bootstrap'
        $dependencies += 'env'
    }
    
    # Standard fragments (30-69) depend on bootstrap and env
    if ($BaseName -match '^([3-6][0-9])-') {
        $dependencies += 'bootstrap'
        $dependencies += 'env'
    }
    
    # Optional fragments (70-99) depend on bootstrap and env
    if ($BaseName -match '^([7-9][0-9])-') {
        $dependencies += 'bootstrap'
        $dependencies += 'env'
    }
    
    # Remove duplicates and return
    return $dependencies | Select-Object -Unique
}

# Extract fragment name from numbered name
function Get-FragmentName {
    param([string]$BaseName)
    
    if ($BaseName -match '^\d+-(.+)') {
        return $matches[1]
    }
    
    return $BaseName
}

# Find all PowerShell fragment files
$files = if ($Fragment) {
    # Migrate specific fragment
    $fragmentPattern = if ($Fragment -match '\.ps1$') {
        $Fragment
    }
    else {
        "$Fragment.ps1"
    }
    
    $fragmentFile = Get-ChildItem -Path $Path -Filter $fragmentPattern -File -ErrorAction SilentlyContinue
    if ($fragmentFile) {
        @($fragmentFile)
    }
    else {
        Write-Warning "Fragment not found: $Fragment"
        @()
    }
}
else {
    # Find all numbered fragments
    Get-ChildItem -Path $Path -Filter '*.ps1' -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.BaseName -match '^\d+-' }
}

if ($files.Count -eq 0) {
    Write-Warning "No numbered fragments found in: $Path"
    exit 0
}

Write-Host "`nFound $($files.Count) fragment(s) to migrate:" -ForegroundColor Cyan
foreach ($file in $files) {
    Write-Host "  - $($file.Name)" -ForegroundColor White
}

$migrationPlan = @()

foreach ($file in $files) {
    $baseName = $file.BaseName
    $newName = Get-FragmentName -BaseName $baseName
    $tier = Get-FragmentTierFromNumber -BaseName $baseName
    $dependencies = Get-FragmentDependencies -BaseName $baseName
    
    # Read file content
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Warning "Could not read file: $($file.FullName)"
        continue
    }
    
    # Check if already migrated (has tier declaration)
    if ($content -match '#\s*Tier:\s*(core|essential|standard|optional)') {
        Write-Host "`n⚠️  $($file.Name) appears to already have a tier declaration. Skipping." -ForegroundColor Yellow
        continue
    }
    
    # Build new header with tier and dependencies
    $headerLines = @()
    
    # Add tier declaration
    $headerLines += "# Tier: $tier"
    
    # Add dependencies if any
    if ($dependencies.Count -gt 0) {
        $depsString = $dependencies -join ', '
        $headerLines += "# Dependencies: $depsString"
    }
    
    # Find insertion point (after first comment block or at the top)
    $lines = $content -split "`r?`n"
    $insertIndex = 0
    
    # Skip initial comment blocks
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*#') {
            $insertIndex = $i + 1
        }
        elseif ($lines[$i] -match '^\s*$') {
            # Empty line, continue
        }
        else {
            break
        }
    }
    
    # Insert new header lines
    $newLines = @()
    $newLines += $lines[0..($insertIndex - 1)]
    $newLines += $headerLines
    $newLines += $lines[$insertIndex..($lines.Count - 1)]
    
    $newContent = $newLines -join "`n"
    
    # Update internal references to the old fragment name
    # Replace references like '01-env' with 'env' in the content
    $oldFragmentName = $baseName
    $newFragmentName = $newName
    
    # Check if there's a corresponding numbered directory that should be renamed
    $oldDirName = $baseName
    $newDirName = $newName
    $oldDirPath = Join-Path $file.DirectoryName $oldDirName
    $newDirPath = Join-Path $file.DirectoryName $newDirName
    $hasDirectory = (Test-Path -LiteralPath $oldDirPath -PathType Container -ErrorAction SilentlyContinue)
    
    # Replace fragment name references in comments, error messages, and contexts
    # Pattern 1: Replace in single quotes (fragment name references)
    $newContent = $newContent -replace "(['`"])$([regex]::Escape($oldFragmentName))\1", "`$1$newFragmentName`$1"
    
    # Pattern 2: Replace in double quotes (error messages, contexts)
    $newContent = $newContent -replace "([`"])$([regex]::Escape($oldFragmentName))\1", "`$1$newFragmentName`$1"
    
    # Pattern 3: Replace in comments (but not in file paths)
    $newContent = $newContent -replace "(#\s+)$([regex]::Escape($oldFragmentName))\.ps1", "`$1$newFragmentName.ps1"
    
    # If directory exists, also update directory references in paths
    # This will be done during migration, but we prepare the content here
    if ($hasDirectory) {
        # Update directory references in ModulePath arrays: @('02-files', 'module.ps1') → @('files', 'module.ps1')
        $newContent = $newContent -replace "(['`"])$([regex]::Escape($oldDirName))\1", "`$1$newDirName`$1"
        # Update directory references in Join-Path: Join-Path ... '02-files' → Join-Path ... 'files'
        $newContent = $newContent -replace "(['`"])$([regex]::Escape($oldDirName))\1", "`$1$newDirName`$1"
    }
    
    # Determine new file path
    $newFilePath = Join-Path $file.DirectoryName "$newName.ps1"
    
    $migrationPlan += [pscustomobject]@{
        OldPath      = $file.FullName
        NewPath      = $newFilePath
        OldName      = $file.Name
        NewName      = "$newName.ps1"
        Tier         = $tier
        Dependencies = $dependencies -join ', '
        Content      = $newContent
        HasDirectory = $hasDirectory
        OldDirPath   = if ($hasDirectory) { $oldDirPath } else { $null }
        NewDirPath   = if ($hasDirectory) { $newDirPath } else { $null }
        OldDirName   = if ($hasDirectory) { $oldDirName } else { $null }
        NewDirName   = if ($hasDirectory) { $newDirName } else { $null }
    }
}

Write-Host "`nMigration Plan:" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

foreach ($plan in $migrationPlan) {
    Write-Host "`n$($plan.OldName) → $($plan.NewName)" -ForegroundColor White
    Write-Host "  Tier: $($plan.Tier)" -ForegroundColor Gray
    if ($plan.Dependencies) {
        Write-Host "  Dependencies: $($plan.Dependencies)" -ForegroundColor Gray
    }
    else {
        Write-Host "  Dependencies: (none)" -ForegroundColor Gray
    }
    if ($plan.HasDirectory) {
        Write-Host "  Directory: $($plan.OldDirName) → $($plan.NewDirName)" -ForegroundColor Cyan
    }
}

if ($isDryRun) {
    Write-Host "`n" + ("=" * 60) -ForegroundColor Yellow
    Write-Host "DRY RUN - No files were modified" -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Yellow
    exit 0
}

# Perform migration
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "Performing Migration..." -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

$migratedCount = 0
$errorCount = 0

foreach ($plan in $migrationPlan) {
    try {
        if ($PSCmdlet.ShouldProcess($plan.OldPath, "Migrate to $($plan.NewName)")) {
            # Step 1: Rename directory if it exists (do this first, before updating file content)
            if ($plan.HasDirectory -and $plan.OldDirPath -and $plan.NewDirPath) {
                if (Test-Path -LiteralPath $plan.OldDirPath -PathType Container) {
                    if (-not (Test-Path -LiteralPath $plan.NewDirPath -PathType Container)) {
                        Rename-Item -Path $plan.OldDirPath -NewName $plan.NewDirName -Force
                        Write-Host "✅ Renamed directory: $($plan.OldDirName) → $($plan.NewDirName)" -ForegroundColor Cyan
                    }
                    else {
                        Write-Warning "Directory $($plan.NewDirName) already exists. Skipping directory rename."
                    }
                }
            }
            
            # Step 2: Update content to reference new directory name
            $finalContent = $plan.Content
            if ($plan.HasDirectory -and $plan.OldDirName -and $plan.NewDirName) {
                # Update directory references in paths
                # Pattern: @('02-files', 'module.ps1') → @('files', 'module.ps1')
                $finalContent = $finalContent -replace "(['`"])$([regex]::Escape($plan.OldDirName))\1", "`$1$($plan.NewDirName)`$1"
                # Pattern: Join-Path ... '02-files' → Join-Path ... 'files'
                $finalContent = $finalContent -replace "(['`"])$([regex]::Escape($plan.OldDirName))\1", "`$1$($plan.NewDirName)`$1"
            }
            
            # Step 3: Write new content to new file
            Set-Content -Path $plan.NewPath -Value $finalContent -NoNewline
            
            # Step 4: Remove old file
            Remove-Item -Path $plan.OldPath -Force
            
            Write-Host "✅ Migrated: $($plan.OldName) → $($plan.NewName)" -ForegroundColor Green
            $migratedCount++
        }
    }
    catch {
        Write-Error "Failed to migrate $($plan.OldName): $($_.Exception.Message)"
        $errorCount++
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "Migration Summary:" -ForegroundColor Cyan
Write-Host "  Files migrated: $migratedCount" -ForegroundColor White
if ($errorCount -gt 0) {
    Write-Host "  Errors: $errorCount" -ForegroundColor Red
}
Write-Host ("=" * 60) -ForegroundColor Cyan

if ($errorCount -gt 0) {
    exit 1
}

exit 0

