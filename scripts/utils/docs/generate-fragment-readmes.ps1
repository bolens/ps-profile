<#
scripts/utils/generate-fragment-readmes.ps1

.SYNOPSIS
    Generates minimal README files for each profile.d/*.ps1 fragment.

.DESCRIPTION
    Scans all PowerShell script files in the profile.d directory and generates
    corresponding README.md files for each fragment. The script extracts:
    - A short purpose line from the top-of-file comment block
    - Top-level function declarations and their associated comments
    - Dynamically-created functions (Set-AgentModeFunction, Set-Item Function:, etc.)
    - Enable-* helper functions

    Existing README files are preserved unless -Force is used to overwrite them.

.PARAMETER Force
    If specified, overwrites existing README.md files. Otherwise, existing
    files are skipped and preserved.

.PARAMETER OutputPath
    The output directory for fragment documentation. Can be absolute or relative to the
    repository root. Defaults to "docs/fragments".

.PARAMETER DryRun
    If specified, shows what README files would be generated without actually creating them.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-fragment-readmes.ps1

    Generates README files for all fragments that don't already have one, and copies them
    to docs/fragments/ with an index.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-fragment-readmes.ps1 -Force

    Regenerates all README files, overwriting existing ones.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-fragment-readmes.ps1 -DryRun

    Shows what README files would be generated without actually creating them.

.OUTPUTS
    Creates or updates .README.md files in the profile.d directory, one per
    .ps1 fragment file. Also copies them to the output directory and generates
    an index. Each README includes:
    - Purpose section extracted from file header comments
    - Usage section referencing the source file
    - Functions section listing all detected functions with descriptions
    - Enable helpers section listing lazy-loading helper functions
    - Dependencies and Notes sections

.NOTES
    The script uses pattern matching to detect:
    - Standard function declarations: function FunctionName { ... }
    - Dynamic function creation: Set-AgentModeFunction, Set-Item Function:, etc.
    - Comments above functions (up to 10 lines back)
    - Multiline comment blocks with structured help (.SYNOPSIS, .DESCRIPTION)

Function descriptions are extracted from single-line comments (#) or
    content within multiline comment blocks immediately preceding the function.
#>

param(
    [switch]$Force,
    [string]$OutputPath = "docs/fragments",
    [switch]$DryRun
)

# Suppress PSAvoidUsingEmptyCatchBlock for this file
# Empty catch blocks are used intentionally for graceful degradation when parsing files
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Empty catch blocks used for graceful degradation when parsing optional file content')]

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
# Script is in scripts/utils/docs/, so go up 3 levels to get to repo root, then join with scripts/lib
$repoRootForLib = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$moduleImportPath = Join-Path $repoRootForLib 'scripts' 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Import fragment README modules
$modulesRoot = Join-Path $PSScriptRoot 'modules'
$parserModulePath = Join-Path $modulesRoot 'FragmentReadmeParser.psm1'
$generatorModulePath = Join-Path $modulesRoot 'FragmentReadmeGenerator.psm1'
$indexGeneratorModulePath = Join-Path $modulesRoot 'FragmentIndexGenerator.psm1'

if (Test-Path $parserModulePath) {
    Import-Module $parserModulePath -DisableNameChecking -ErrorAction Stop
}
if (Test-Path $generatorModulePath) {
    Import-Module $generatorModulePath -DisableNameChecking -ErrorAction Stop
}
if (Test-Path $indexGeneratorModulePath) {
    Import-Module $indexGeneratorModulePath -DisableNameChecking -ErrorAction Stop
}

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Get profile directory using shared function
try {
    $fragDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

$psFiles = Get-PowerShellScripts -Path $fragDir -SortByName

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[docs.generate-fragment-readmes] Starting fragment README generation"
    Write-Verbose "[docs.generate-fragment-readmes] Found $($psFiles.Count) fragment file(s)"
    Write-Verbose "[docs.generate-fragment-readmes] Force mode: $Force, Dry run: $DryRun"
}

if ($DryRun) {
    Write-ScriptMessage -Message "DRY RUN MODE: Would generate README files for fragments..." -ForegroundColor Yellow
}

$filesToGenerate = 0
$genStartTime = Get-Date
foreach ($ps in $psFiles) {
    $mdPath = [System.IO.Path]::ChangeExtension($ps.FullName, '.README.md')
    if ((Test-Path $mdPath) -and (-not $Force)) {
        continue
    }

    $filesToGenerate++

    if ($DryRun) {
        Write-ScriptMessage -Message "[DRY RUN] Would generate README: $($ps.Name) -> $(Split-Path $mdPath -Leaf)" -ForegroundColor Yellow
        continue
    }

    # Level 1: Individual fragment processing
    if ($debugLevel -ge 1) {
        Write-Verbose "[docs.generate-fragment-readmes] Processing fragment: $($ps.Name)"
    }
    
    $fragStartTime = Get-Date
    try {
        # Extract fragment information
        $purpose = Get-FragmentPurpose -FilePath $ps.FullName -FileInfo $ps -ErrorAction Stop
        $functions = Get-FragmentFunctions -FilePath $ps.FullName -ErrorAction Stop
        $enableHelpers = Get-FragmentEnableHelpers -FilePath $ps.FullName -ErrorAction Stop
        
        $fragDuration = ((Get-Date) - $fragStartTime).TotalMilliseconds
        
        # Level 2: Fragment processing timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[docs.generate-fragment-readmes] Fragment $($ps.Name) processed in ${fragDuration}ms - Functions: $($functions.Count), Helpers: $($enableHelpers.Count)"
        }

        # Ensure we have at least a purpose
        if ([string]::IsNullOrWhiteSpace($purpose)) {
            $purpose = "See the fragment source file for details."
        }

        # Generate markdown content
        $mdContent = New-FragmentReadmeContent -FileName $ps.Name -Purpose $purpose -Functions $functions -EnableHelpers $enableHelpers -ErrorAction Stop

        # Ensure content is not empty
        if ([string]::IsNullOrWhiteSpace($mdContent)) {
            throw "Generated content is empty"
        }

        # Write README file
        $mdContent | Out-File -FilePath $mdPath -Encoding utf8 -Force
        Write-ScriptMessage -Message ("Created: {0}" -f (Split-Path $mdPath -Leaf))
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to generate README for fragment" -OperationName 'docs.generate-fragment-readme' -Context @{
                fragment_name = $ps.Name
                fragment_path = $ps.FullName
            } -Code 'FragmentReadmeGenerationFailed'
        }
        else {
            Write-Warning "Failed to generate README for $($ps.Name): $($_.Exception.Message)"
        }
        # Create a minimal README with basic info
        $displayFileName = $ps.Name
        if ($ps.Name -match '^\d+-(.+)') {
            $displayFileName = $matches[1]
        }
        $minimalContent = @"
profile.d/$displayFileName

Purpose
-------
See the fragment source file for details.

Usage
-----
See the fragment source: ``$displayFileName`` for examples and usage notes.

Functions
---------
(Unable to parse functions - see source file)

Dependencies
------------
None explicit; see the fragment for runtime checks and optional tooling dependencies.

Notes
-----
Keep this fragment idempotent and avoid heavy probes at dot-source. Prefer provider-first checks and lazy enablers like Enable-* helpers.
"@
        $minimalContent | Out-File -FilePath $mdPath -Encoding utf8 -Force
        Write-ScriptMessage -Message ("Created minimal README: {0}" -f (Split-Path $mdPath -Leaf))
    }
}

# Copy fragment READMEs to output directory and generate index
if (-not $DryRun) {
    Write-ScriptMessage -Message "`nCopying fragment READMEs to output directory..."
}
else {
    Write-ScriptMessage -Message "`n[DRY RUN] Would copy fragment READMEs to output directory..." -ForegroundColor Yellow
}

# Handle OutputPath - if it's absolute, use it directly, otherwise join with repo root
if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $fragmentsDocsPath = $OutputPath
}
else {
    $fragmentsDocsPath = Join-Path $repoRoot $OutputPath
}

# Create fragments docs directory if it doesn't exist
if (-not $DryRun) {
    Ensure-DirectoryExists -Path $fragmentsDocsPath
}

# Track which fragments we're processing
$processedFragmentNames = [System.Collections.Generic.List[string]]::new()

# Copy all fragment READMEs to the output directory
$copyErrors = [System.Collections.Generic.List[string]]::new()
$copyStartTime = Get-Date
foreach ($ps in $psFiles) {
    $sourceReadme = [System.IO.Path]::ChangeExtension($ps.FullName, '.README.md')
    if (Test-Path $sourceReadme) {
        # Use base name without .README extension for cleaner filenames
        $destReadme = Join-Path $fragmentsDocsPath "$($ps.BaseName).md"
        if ($DryRun) {
            Write-ScriptMessage -Message "[DRY RUN] Would copy: $($ps.BaseName).md -> $destReadme" -ForegroundColor Yellow
            $processedFragmentNames.Add($ps.BaseName)
        }
        else {
            try {
                Copy-Item -Path $sourceReadme -Destination $destReadme -Force -ErrorAction Stop
                Write-ScriptMessage -Message ("Copied: $($ps.BaseName).md")
                $processedFragmentNames.Add($ps.BaseName)
            }
            catch {
                $copyErrors.Add($ps.BaseName)
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to copy fragment README" -OperationName 'docs.generate-fragment-readme.copy' -Context @{
                        fragment_name = $ps.BaseName
                        source_path   = $sourceReadme
                        dest_path     = $destReadme
                    } -Code 'FragmentReadmeCopyFailed'
                }
                else {
                    Write-ScriptMessage -Message "Failed to copy README for $($ps.BaseName): $($_.Exception.Message)" -IsWarning
                }
            }
        }
    }
}

$copyDuration = ((Get-Date) - $copyStartTime).TotalMilliseconds

# Level 2: Copy timing
if ($debugLevel -ge 2) {
    Write-Verbose "[docs.generate-fragment-readmes] Copy operation completed in ${copyDuration}ms"
    Write-Verbose "[docs.generate-fragment-readmes] Files copied: $($processedFragmentNames.Count), Errors: $($copyErrors.Count)"
}

if ($copyErrors.Count -gt 0 -and -not $DryRun) {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message "Some fragment READMEs failed to copy" -OperationName 'docs.generate-fragment-readme.copy' -Context @{
            failed_fragments = $copyErrors -join ','
            failed_count     = $copyErrors.Count
            total_processed  = $processedFragmentNames.Count
        } -Code 'FragmentReadmeCopyPartialFailure'
    }
    else {
        Write-ScriptMessage -Message "Warning: Failed to copy $($copyErrors.Count) fragment README(s): $($copyErrors -join ', ')" -IsWarning
    }
}

# Clean up all fragment README files from profile.d/ (they're now in docs/fragments/)
$allProfileReadmes = Get-ChildItem -Path $fragDir -Filter '*.README.md' -ErrorAction SilentlyContinue

if ($allProfileReadmes.Count -gt 0) {
    if ($DryRun) {
        Write-ScriptMessage -Message "`n[DRY RUN] Would remove $($allProfileReadmes.Count) fragment README file(s) from profile.d/:" -ForegroundColor Yellow
        foreach ($readme in $allProfileReadmes) {
            Write-ScriptMessage -Message "  - Would remove $($readme.Name)" -ForegroundColor Yellow
        }
    }
    else {
        Write-ScriptMessage -Message "`nCleaning up fragment README files from profile.d/ (moved to docs/fragments/)..."
        Write-ScriptMessage -Message "Removing $($allProfileReadmes.Count) fragment README file(s) from profile.d/ (now in docs/fragments/):"
        $cleanupErrors = [System.Collections.Generic.List[string]]::new()
        foreach ($readme in $allProfileReadmes) {
            try {
                Remove-Item -Path $readme.FullName -Force -ErrorAction Stop
                Write-ScriptMessage -Message "  - Removing $($readme.Name)"
            }
            catch {
                $cleanupErrors.Add($readme.Name)
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to remove fragment README" -OperationName 'docs.generate-fragment-readme.cleanup' -Context @{
                        readme_name = $readme.Name
                        readme_path = $readme.FullName
                    } -Code 'FragmentReadmeCleanupFailed'
                }
                else {
                    Write-ScriptMessage -Message "Failed to remove $($readme.Name): $($_.Exception.Message)" -IsWarning
                }
            }
        }
        if ($cleanupErrors.Count -gt 0) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Some fragment READMEs failed to remove" -OperationName 'docs.generate-fragment-readme.cleanup' -Context @{
                    failed_readmes = $cleanupErrors -join ','
                    failed_count   = $cleanupErrors.Count
                } -Code 'FragmentReadmeCleanupPartialFailure'
            }
        }
    }
}
else {
    Write-ScriptMessage -Message "No fragment README files found in profile.d/."
}

# Clean up stale fragment documentation files from docs/fragments/
if (Test-Path $fragmentsDocsPath) {
    $allFragmentDocs = Get-ChildItem -Path $fragmentsDocsPath -Filter '*.md' -Exclude 'README.md' -ErrorAction SilentlyContinue
    $staleFragmentDocs = $allFragmentDocs | Where-Object { 
        $fragmentBaseName = $_.BaseName
        $fragmentBaseName -notin $processedFragmentNames
    }

    if ($staleFragmentDocs.Count -gt 0) {
        if ($DryRun) {
            Write-ScriptMessage -Message "`n[DRY RUN] Would remove $($staleFragmentDocs.Count) stale fragment documentation file(s) from docs/fragments/:" -ForegroundColor Yellow
            foreach ($staleDoc in $staleFragmentDocs) {
                Write-ScriptMessage -Message "  - Would remove $($staleDoc.Name)" -ForegroundColor Yellow
            }
        }
        else {
            Write-ScriptMessage -Message "`nCleaning up stale fragment documentation files from docs/fragments/..."
            Write-ScriptMessage -Message "Removing $($staleFragmentDocs.Count) stale fragment documentation file(s) from docs/fragments/:"
            foreach ($staleDoc in $staleFragmentDocs) {
                Write-ScriptMessage -Message "  - Removing $($staleDoc.Name)"
                Remove-Item -Path $staleDoc.FullName -Force
            }
        }
    }
    else {
        Write-ScriptMessage -Message "No stale fragment documentation files found in docs/fragments/."
    }
}

# Generate fragment index
if (-not $DryRun) {
    try {
        if (Get-Command Write-FragmentIndex -ErrorAction SilentlyContinue) {
            Write-ScriptMessage -Message "`nGenerating fragment index..."
            Write-FragmentIndex -FragmentsPath $fragmentsDocsPath -ProfilePath $fragDir -ErrorAction Stop
        }
        else {
            Write-Warning "Write-FragmentIndex function not available. Index generation skipped."
        }
    }
    catch {
        Write-Warning "Failed to generate fragment index: $($_.Exception.Message)"
        # Don't fail the entire script if index generation fails
    }
}
else {
    Write-ScriptMessage -Message "`n[DRY RUN] Would generate fragment index..." -ForegroundColor Yellow
}

if ($DryRun) {
    Write-ScriptMessage -Message "`n[DRY RUN] Would generate $filesToGenerate README file(s)" -ForegroundColor Yellow
    Write-ScriptMessage -Message "Run without -DryRun to apply changes." -ForegroundColor Yellow
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "DRY RUN: Would generate fragment README files and index."
}
else {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message 'Done generating fragment README files and index.'
}
