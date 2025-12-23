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

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-fragment-readmes.ps1

    Generates README files for all fragments that don't already have one, and copies them
    to docs/fragments/ with an index.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-fragment-readmes.ps1 -Force

    Regenerates all README files, overwriting existing ones.

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
    [string]$OutputPath = "docs/fragments"
)

# Suppress PSAvoidUsingEmptyCatchBlock for this file
# Empty catch blocks are used intentionally for graceful degradation when parsing files
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Empty catch blocks used for graceful degradation when parsing optional file content')]

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
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Get profile directory using shared function
try {
    $fragDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$psFiles = Get-PowerShellScripts -Path $fragDir -SortByName

foreach ($ps in $psFiles) {
    $mdPath = [System.IO.Path]::ChangeExtension($ps.FullName, '.README.md')
    if ((Test-Path $mdPath) -and (-not $Force)) {
        continue
    }

    try {
        # Extract fragment information
        $purpose = Get-FragmentPurpose -FilePath $ps.FullName -FileInfo $ps -ErrorAction Stop
        $functions = Get-FragmentFunctions -FilePath $ps.FullName -ErrorAction Stop
        $enableHelpers = Get-FragmentEnableHelpers -FilePath $ps.FullName -ErrorAction Stop

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
        Write-Warning "Failed to generate README for $($ps.Name): $($_.Exception.Message)"
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
Write-ScriptMessage -Message "`nCopying fragment READMEs to output directory..."

# Handle OutputPath - if it's absolute, use it directly, otherwise join with repo root
if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $fragmentsDocsPath = $OutputPath
}
else {
    $fragmentsDocsPath = Join-Path $repoRoot $OutputPath
}

# Create fragments docs directory if it doesn't exist
Ensure-DirectoryExists -Path $fragmentsDocsPath

# Track which fragments we're processing
$processedFragmentNames = [System.Collections.Generic.List[string]]::new()

# Copy all fragment READMEs to the output directory
foreach ($ps in $psFiles) {
    $sourceReadme = [System.IO.Path]::ChangeExtension($ps.FullName, '.README.md')
    if (Test-Path $sourceReadme) {
        # Use base name without .README extension for cleaner filenames
        $destReadme = Join-Path $fragmentsDocsPath "$($ps.BaseName).md"
        Copy-Item -Path $sourceReadme -Destination $destReadme -Force
        $processedFragmentNames.Add($ps.BaseName)
        Write-ScriptMessage -Message ("Copied: $($ps.BaseName).md")
    }
}

# Clean up all fragment README files from profile.d/ (they're now in docs/fragments/)
Write-ScriptMessage -Message "`nCleaning up fragment README files from profile.d/ (moved to docs/fragments/)..."
$allProfileReadmes = Get-ChildItem -Path $fragDir -Filter '*.README.md' -ErrorAction SilentlyContinue

if ($allProfileReadmes.Count -gt 0) {
    Write-ScriptMessage -Message "Removing $($allProfileReadmes.Count) fragment README file(s) from profile.d/ (now in docs/fragments/):"
    foreach ($readme in $allProfileReadmes) {
        Write-ScriptMessage -Message "  - Removing $($readme.Name)"
        Remove-Item -Path $readme.FullName -Force
    }
}
else {
    Write-ScriptMessage -Message "No fragment README files found in profile.d/."
}

# Clean up stale fragment documentation files from docs/fragments/
Write-ScriptMessage -Message "`nCleaning up stale fragment documentation files from docs/fragments/..."
if (Test-Path $fragmentsDocsPath) {
    $allFragmentDocs = Get-ChildItem -Path $fragmentsDocsPath -Filter '*.md' -Exclude 'README.md' -ErrorAction SilentlyContinue
    $staleFragmentDocs = $allFragmentDocs | Where-Object { 
        $fragmentBaseName = $_.BaseName
        $fragmentBaseName -notin $processedFragmentNames
    }

    if ($staleFragmentDocs.Count -gt 0) {
        Write-ScriptMessage -Message "Removing $($staleFragmentDocs.Count) stale fragment documentation file(s) from docs/fragments/:"
        foreach ($staleDoc in $staleFragmentDocs) {
            Write-ScriptMessage -Message "  - Removing $($staleDoc.Name)"
            Remove-Item -Path $staleDoc.FullName -Force
        }
    }
    else {
        Write-ScriptMessage -Message "No stale fragment documentation files found in docs/fragments/."
    }
}

# Generate fragment index
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

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'Done generating fragment README files and index.'
