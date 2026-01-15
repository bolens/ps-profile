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

.PARAMETER DryRun
    If specified, shows what documentation would be generated without actually creating files.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-docs.ps1

    Generates documentation in the default docs/api directory with functions and aliases
    in separate subdirectories.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-docs.ps1 -OutputPath ".\documentation"

    Generates documentation in a custom directory.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\generate-docs.ps1 -DryRun

    Shows what documentation would be generated without actually creating files.
#>

param(
    [string]$OutputPath = "docs/api",
    [string]$ProfilePath,
    [switch]$DryRun
)

# Import ModuleImport first (bootstrap)
# Script is in scripts/utils/docs/, so go up 3 levels to get to repo root, then join with scripts/lib
$repoRootForLib = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$moduleImportPath = Join-Path $repoRootForLib 'scripts' 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
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
        Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to determine repository root from script path: $PSScriptRoot"
    }
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
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
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "OutputPath cannot be null or empty"
}

# Use provided ProfilePath or default to repo root profile.d
if ([string]::IsNullOrWhiteSpace($ProfilePath)) {
    $profilePath = Join-Path $repoRoot 'profile.d'
}
else {
    $profilePath = $ProfilePath
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[docs.generate] Starting API documentation generation"
    Write-Verbose "[docs.generate] Output path: $OutputPath, Profile path: $ProfilePath, Dry run: $DryRun"
}

if ($DryRun) {
    Write-ScriptMessage -Message "DRY RUN MODE: Would generate API documentation..." -ForegroundColor Yellow
}
else {
    Write-ScriptMessage -Message "Generating API documentation..."
}

# Create docs directory if it doesn't exist
if (-not $DryRun) {
    Ensure-DirectoryExists -Path $docsPath
}

# Create subdirectories for functions and aliases
$functionsPath = Join-Path $docsPath 'functions'
$aliasesPath = Join-Path $docsPath 'aliases'
if (-not $DryRun) {
    Ensure-DirectoryExists -Path $functionsPath
    Ensure-DirectoryExists -Path $aliasesPath
}

# Track which commands we're documenting (to clean up stale docs later)
# Use List for better performance than array concatenation
$documentedCommandNames = [System.Collections.Generic.List[string]]::new()

# Level 1: Command parsing start
if ($debugLevel -ge 1) {
    Write-Verbose "[docs.generate] Parsing documented commands from profile path"
}

# Parse functions and aliases from profile files
$parseStartTime = Get-Date
$parsedData = Get-DocumentedCommands -ProfilePath $profilePath
$parseDuration = ((Get-Date) - $parseStartTime).TotalMilliseconds

# Level 2: Command parsing timing
if ($debugLevel -ge 2) {
    Write-Verbose "[docs.generate] Command parsing completed in ${parseDuration}ms"
}

if (-not $parsedData) {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to parse documented commands from profile path: $profilePath"
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
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "No functions or aliases with documentation found."
}

Write-ScriptMessage -Message "Found $($functions.Count) functions and $($aliases.Count) aliases with documentation."
Write-DocsDebugMessage -Message "Functions path: $functionsPath" -ForegroundColor Cyan
Write-DocsDebugMessage -Message "Aliases path: $aliasesPath" -ForegroundColor Cyan
Write-DocsDebugMessage -Message "Functions count: $($functions.Count)" -ForegroundColor Cyan

if ($DryRun) {
    Write-ScriptMessage -Message "[DRY RUN] Would generate documentation for:" -ForegroundColor Yellow
    Write-ScriptMessage -Message "  - $($functions.Count) function(s) in $functionsPath" -ForegroundColor Yellow
    Write-ScriptMessage -Message "  - $($aliases.Count) alias(es) in $aliasesPath" -ForegroundColor Yellow
    Write-ScriptMessage -Message "  - Index file in $docsPath" -ForegroundColor Yellow
}
else {
    $generationErrors = [System.Collections.Generic.List[string]]::new()
    $generationSuccess = @{
        Functions = $false
        Aliases   = $false
        Index     = $false
        Cleanup   = $false
    }
    
    # Level 1: Function documentation generation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[docs.generate] Generating function documentation"
    }
    
    # Generate markdown documentation for functions
    $functionsStartTime = Get-Date
    try {
        Write-FunctionDocumentation -Functions $functions -Aliases $aliases -DocsPath $functionsPath -DocumentedCommandNames $documentedCommandNames -ErrorAction Stop
        $functionsDuration = ((Get-Date) - $functionsStartTime).TotalMilliseconds
        
        # Level 2: Function documentation timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[docs.generate] Function documentation generated in ${functionsDuration}ms"
        }
        
        $generationSuccess.Functions = $true
    }
    catch {
        $generationErrors.Add("Function documentation: $($_.Exception.Message)")
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'docs.generate.functions' -Context @{
                functions_path = $functionsPath
                function_count = $functions.Count
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to generate function documentation: $($_.Exception.Message)" -IsWarning
        }
    }
    
    # Level 1: Alias documentation generation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[docs.generate] Generating alias documentation"
    }
    
    # Generate markdown documentation for aliases
    $aliasesStartTime = Get-Date
    try {
        Write-AliasDocumentation -Aliases $aliases -DocsPath $aliasesPath -DocumentedCommandNames $documentedCommandNames -ErrorAction Stop
        $aliasesDuration = ((Get-Date) - $aliasesStartTime).TotalMilliseconds
        
        # Level 2: Alias documentation timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[docs.generate] Alias documentation generated in ${aliasesDuration}ms"
        }
        
        $generationSuccess.Aliases = $true
    }
    catch {
        $generationErrors.Add("Alias documentation: $($_.Exception.Message)")
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'docs.generate.aliases' -Context @{
                aliases_path = $aliasesPath
                alias_count  = $aliases.Count
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to generate alias documentation: $($_.Exception.Message)" -IsWarning
        }
    }
    
    # Level 1: Index generation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[docs.generate] Generating documentation index"
    }
    
    # Generate index file
    $indexStartTime = Get-Date
    try {
        Write-DocumentationIndex -Functions $functions -Aliases $aliases -DocsPath $docsPath -ErrorAction Stop
        $indexDuration = ((Get-Date) - $indexStartTime).TotalMilliseconds
        
        # Level 2: Index generation timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[docs.generate] Documentation index generated in ${indexDuration}ms"
        }
        
        $generationSuccess.Index = $true
    }
    catch {
        $generationErrors.Add("Index generation: $($_.Exception.Message)")
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'docs.generate.index' -Context @{
                docs_path = $docsPath
            }
        }
        else {
            Write-ScriptMessage -Message "Failed to generate index: $($_.Exception.Message)" -IsWarning
        }
    }
    
    # Level 1: Cleanup start
    if ($debugLevel -ge 1) {
        Write-Verbose "[docs.generate] Cleaning up stale documentation files"
    }
    
    # Clean up stale documentation files from both subdirectories
    $cleanupStartTime = Get-Date
    try {
        Remove-StaleDocumentation -DocsPath $functionsPath -DocumentedCommandNames $documentedCommandNames -ErrorAction Stop
        Remove-StaleDocumentation -DocsPath $aliasesPath -DocumentedCommandNames $documentedCommandNames -ErrorAction Stop
        $cleanupDuration = ((Get-Date) - $cleanupStartTime).TotalMilliseconds
        
        # Level 2: Cleanup timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[docs.generate] Cleanup completed in ${cleanupDuration}ms"
        }
        
        $generationSuccess.Cleanup = $true
    }
    catch {
        $generationErrors.Add("Cleanup: $($_.Exception.Message)")
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to clean up stale documentation" -OperationName 'docs.generate.cleanup' -Context @{
                functions_path = $functionsPath
                aliases_path   = $aliasesPath
            } -Code 'DocsCleanupFailed'
        }
        else {
            Write-ScriptMessage -Message "Failed to clean up stale documentation: $($_.Exception.Message)" -IsWarning
        }
    }
    
    if ($generationErrors.Count -gt 0) {
        $successCount = ($generationSuccess.Values | Where-Object { $_ }).Count
        if ($successCount -gt 0) {
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Documentation generation completed with some failures" -OperationName 'docs.generate' -Context @{
                    successful_steps = $successCount
                    failed_steps     = $generationErrors.Count
                    errors           = $generationErrors -join '; '
                } -Code 'DocsPartialFailure'
            }
            else {
                Write-ScriptMessage -Message "Warning: Documentation generation completed with $($generationErrors.Count) error(s): $($generationErrors -join '; ')" -IsWarning
            }
        }
    }
    
    $totalDuration = $parseDuration + $functionsDuration + $aliasesDuration + $indexDuration + $cleanupDuration
    
    # Level 2: Overall generation timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[docs.generate] Documentation generation completed in ${totalDuration}ms"
        Write-Verbose "[docs.generate] Parse: ${parseDuration}ms, Functions: ${functionsDuration}ms, Aliases: ${aliasesDuration}ms, Index: ${indexDuration}ms, Cleanup: ${cleanupDuration}ms"
    }
    
    # Level 3: Performance breakdown
    if ($debugLevel -ge 3) {
        Write-Host "  [docs.generate] Performance - Parse: ${parseDuration}ms, Functions: ${functionsDuration}ms, Aliases: ${aliasesDuration}ms, Index: ${indexDuration}ms, Cleanup: ${cleanupDuration}ms, Total: ${totalDuration}ms" -ForegroundColor DarkGray
    }
}

# Clean up ALL old function and alias documentation files from root docs/ directory (migrated to docs/api/functions/ and docs/api/aliases/)
$oldDocsPath = Split-Path -Parent $docsPath
if ($oldDocsPath -and -not [string]::IsNullOrWhiteSpace($oldDocsPath) -and (Test-Path -LiteralPath $oldDocsPath)) {
    # Get all markdown files in root docs/ that look like function or alias docs
    # Exclude README.md and files in subdirectories (api/, fragments/, guides/)
    $oldDocFiles = Get-ChildItem -Path $oldDocsPath -Filter '*.md' -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.Name -ne 'README.md' -and
        $_.DirectoryName -eq $oldDocsPath -and
        ($_.Name -match '^[A-Z]' -or $_.Name -match '^[a-z]')
    }
    
    if ($oldDocFiles.Count -gt 0) {
        if ($DryRun) {
            Write-ScriptMessage -Message "`n[DRY RUN] Would remove $($oldDocFiles.Count) old documentation file(s) from root docs/ directory:" -ForegroundColor Yellow
            foreach ($oldFile in $oldDocFiles) {
                Write-ScriptMessage -Message "  - Would remove $($oldFile.Name)" -ForegroundColor Yellow
            }
        }
        else {
            Write-ScriptMessage -Message "`nCleaning up old function and alias documentation files from root docs/ directory (moved to docs/api/)..."
            Write-ScriptMessage -Message "Removing $($oldDocFiles.Count) old documentation file(s) from root docs/ directory (now in docs/api/):"
            foreach ($oldFile in $oldDocFiles) {
                Write-ScriptMessage -Message "  - Removing $($oldFile.Name)"
                Remove-Item -Path $oldFile.FullName -Force
            }
        }
    }
    else {
        Write-ScriptMessage -Message "No old documentation files found in root docs/ directory."
    }
}

if ($DryRun) {
    Write-ScriptMessage -Message "`n[DRY RUN] Would generate API documentation in: $docsPath" -ForegroundColor Yellow
    Write-ScriptMessage -Message "Run without -DryRun to apply changes." -ForegroundColor Yellow
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "DRY RUN: Would generate documentation for $($functions.Count) functions and $($aliases.Count) aliases."
}
else {
    Write-ScriptMessage -Message "`nAPI documentation generated in: $docsPath"
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "Generated documentation for $($functions.Count) functions and $($aliases.Count) aliases."
}
