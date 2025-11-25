<#
scripts/utils/generate-docs.ps1

.SYNOPSIS
    Generates API documentation from comment-based help in PowerShell functions.

.DESCRIPTION
    Scans all PowerShell script files in the profile.d directory and generates markdown
    documentation files from comment-based help. Extracts functions, aliases, parameters,
    examples, and other help content. Creates individual markdown files for each function
    and alias, plus an index file.

.PARAMETER OutputPath
    The output directory for generated documentation. Can be absolute or relative to the
    repository root. Defaults to "docs/api".

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-docs.ps1

    Generates documentation in the default docs/api directory with functions and aliases
    in separate subdirectories.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-docs.ps1 -OutputPath ".\documentation"

    Generates documentation in a custom directory.
#>

param(
    [string]$OutputPath = "docs/api",
    [string]$ProfilePath
)

# Import ModuleImport first (bootstrap)
# Script is in scripts/utils/docs/, so go up 3 levels to get to repo root, then join with scripts/lib
$repoRootForLib = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$moduleImportPath = Join-Path $repoRootForLib 'scripts' 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Import documentation modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
# Remove modules first to ensure fresh import
Remove-Module DocParser, DocGenerator, DocIndexGenerator, DocCleanup -ErrorAction SilentlyContinue
Import-Module (Join-Path $modulesPath 'DocParser.psm1') -ErrorAction Stop -Force
Import-Module (Join-Path $modulesPath 'DocGenerator.psm1') -ErrorAction Stop -Force
Import-Module (Join-Path $modulesPath 'DocIndexGenerator.psm1') -ErrorAction Stop -Force
Import-Module (Join-Path $modulesPath 'DocCleanup.psm1') -ErrorAction Stop -Force

<#
.SYNOPSIS
    Determines whether documentation debug output should be written.

.DESCRIPTION
    Checks PS_PROFILE_DEBUG env var and DebugPreference to decide if verbose
    documentation diagnostics should be shown.

.OUTPUTS
    System.Boolean
#>
function Test-DocsDebugEnabled {
    if ($env:PS_PROFILE_DEBUG) {
        return $true
    }

    return $DebugPreference -in @('Continue', 'Inquire')
}

<#
.SYNOPSIS
    Writes a structured documentation debug message when debug is enabled.

.DESCRIPTION
    Emits "[DEBUG]" tagged messages to host output only when Test-DocsDebugEnabled
    indicates diagnostics should be shown.

.PARAMETER Message
    Text to display.
.PARAMETER ForegroundColor
    Optional color for distinguishing message categories.
#>
function Write-DocsDebugMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Gray
    )

    if (-not (Test-DocsDebugEnabled)) {
        return
    }

    if ($ForegroundColor) {
        Write-Host "[DEBUG] $Message" -ForegroundColor $ForegroundColor
    }
    else {
        Write-Host "[DEBUG] $Message"
    }
}

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    if (-not $repoRoot) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to determine repository root from script path: $PSScriptRoot"
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Handle OutputPath - if it's absolute, use it directly, otherwise join with repo root
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = "docs"
}

if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $docsPath = $OutputPath
}
else {
    $docsPath = Join-Path $repoRoot $OutputPath
}

if ([string]::IsNullOrWhiteSpace($docsPath)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "OutputPath cannot be null or empty"
}

# Use provided ProfilePath or default to repo root profile.d
if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
    $profilePath = Join-Path $repoRoot 'profile.d'
}
else {
    $profilePath = $ProfilePath
}

Write-ScriptMessage -Message "Generating API documentation..."

# Create docs directory if it doesn't exist
Ensure-DirectoryExists -Path $docsPath

# Create subdirectories for functions and aliases
$functionsPath = Join-Path $docsPath 'functions'
$aliasesPath = Join-Path $docsPath 'aliases'
Ensure-DirectoryExists -Path $functionsPath
Ensure-DirectoryExists -Path $aliasesPath

# Track which commands we're documenting (to clean up stale docs later)
# Use List for better performance than array concatenation
$documentedCommandNames = [System.Collections.Generic.List[string]]::new()

# Parse functions and aliases from profile files
$parsedData = Get-DocumentedCommands -ProfilePath $profilePath
if (-not $parsedData) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to parse documented commands from profile path: $profilePath"
}

$functions = $parsedData.Functions
$aliases = $parsedData.Aliases

# Initialize empty lists if null
if (-not $functions) {
    $functions = [System.Collections.Generic.List[PSCustomObject]]::new()
}
if (-not $aliases) {
    $aliases = [System.Collections.Generic.List[PSCustomObject]]::new()
}

if ($functions.Count -eq 0 -and $aliases.Count -eq 0) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "No functions or aliases with documentation found."
}

Write-ScriptMessage -Message "Found $($functions.Count) functions and $($aliases.Count) aliases with documentation."
Write-DocsDebugMessage -Message "Functions path: $functionsPath" -ForegroundColor Cyan
Write-DocsDebugMessage -Message "Aliases path: $aliasesPath" -ForegroundColor Cyan
Write-DocsDebugMessage -Message "Functions count: $($functions.Count)" -ForegroundColor Cyan

# Generate markdown documentation for functions
Write-FunctionDocumentation -Functions $functions -Aliases $aliases -DocsPath $functionsPath -DocumentedCommandNames $documentedCommandNames

# Generate markdown documentation for aliases
Write-AliasDocumentation -Aliases $aliases -DocsPath $aliasesPath -DocumentedCommandNames $documentedCommandNames

# Generate index file
Write-DocumentationIndex -Functions $functions -Aliases $aliases -DocsPath $docsPath

# Clean up stale documentation files from both subdirectories
Remove-StaleDocumentation -DocsPath $functionsPath -DocumentedCommandNames $documentedCommandNames
Remove-StaleDocumentation -DocsPath $aliasesPath -DocumentedCommandNames $documentedCommandNames

# Clean up ALL old function and alias documentation files from root docs/ directory (migrated to docs/api/functions/ and docs/api/aliases/)
$oldDocsPath = Split-Path -Parent $docsPath
if (Test-Path $oldDocsPath) {
    Write-ScriptMessage -Message "`nCleaning up old function and alias documentation files from root docs/ directory (moved to docs/api/)..."
    
    # Get all markdown files in root docs/ that look like function or alias docs
    # Exclude README.md and files in subdirectories (api/, fragments/, guides/)
    $oldDocFiles = Get-ChildItem -Path $oldDocsPath -Filter '*.md' -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.Name -ne 'README.md' -and
        $_.DirectoryName -eq $oldDocsPath -and
        ($_.Name -match '^[A-Z]' -or $_.Name -match '^[a-z]')
    }
    
    if ($oldDocFiles.Count -gt 0) {
        Write-ScriptMessage -Message "Removing $($oldDocFiles.Count) old documentation file(s) from root docs/ directory (now in docs/api/):"
        foreach ($oldFile in $oldDocFiles) {
            Write-ScriptMessage -Message "  - Removing $($oldFile.Name)"
            Remove-Item -Path $oldFile.FullName -Force
        }
    }
    else {
        Write-ScriptMessage -Message "No old documentation files found in root docs/ directory."
    }
}

Write-ScriptMessage -Message "`nAPI documentation generated in: $docsPath"
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Generated documentation for $($functions.Count) functions and $($aliases.Count) aliases."
