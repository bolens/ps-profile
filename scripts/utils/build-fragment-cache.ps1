<#
.SYNOPSIS
    Builds/warms the fragment cache by parsing all fragments.

.DESCRIPTION
    Parses all fragment files to populate the fragment cache (both in-memory and SQLite database).
    This script is useful for:
    - Pre-warming the cache before profile load
    - Rebuilding cache after clearing it
    - Ensuring all fragments are cached for faster subsequent loads
    
    The script discovers all fragment files in profile.d/, initializes the cache system,
    and parses all fragments to populate both content and AST caches.

.PARAMETER WhatIf
    Shows what would be built without actually building the cache (dry-run mode).

.PARAMETER Force
    Forces building even if some fragments fail. By default, the script continues
    on errors but reports them.

.PARAMETER FragmentPath
    Optional path to profile.d directory. Defaults to discovering from repository root.

.PARAMETER UseAstParsing
    Whether to use AST parsing (slower but more accurate). Defaults to checking
    PS_PROFILE_USE_AST_PARSING environment variable.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1
    
    Builds the fragment cache by parsing all fragments.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1 -WhatIf
    
    Shows what would be built without actually building the cache.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1 -FragmentPath "C:\path\to\profile.d"
    
    Builds cache for fragments in a specific directory.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    
    [string]$FragmentPath = $null,
    
    [switch]$UseAstParsing = $false
)

# Import shared utilities directly (similar to clear-fragment-cache.ps1)
# Calculate lib path manually to avoid circular dependency with Get-RepoRoot
# For scripts in scripts/utils/, calculate scripts dir manually
# $PSScriptRoot = scripts/utils, so go up 1 level to get scripts/
$scriptsDir = Split-Path -Parent $PSScriptRoot
$libPath = Join-Path $scriptsDir 'lib'
$repoRoot = Split-Path -Parent $scriptsDir

# Load .env file BEFORE parsing debug level so environment variables are available
# This ensures PS_PROFILE_USE_AST_PARSING and PS_PROFILE_DEBUG from .env are loaded
try {
    $envFileModulePath = Join-Path $libPath 'utilities' 'EnvFile.psm1'
    if (Test-Path -LiteralPath $envFileModulePath) {
        Import-Module $envFileModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
        # Try Initialize-EnvFiles first (loads .env and .env.local)
        if (Get-Command Initialize-EnvFiles -ErrorAction SilentlyContinue) {
            Initialize-EnvFiles -RepoRoot $repoRoot -ErrorAction SilentlyContinue
        }
        # Fallback to Load-EnvFile if Initialize-EnvFiles not available
        elseif (Get-Command Load-EnvFile -ErrorAction SilentlyContinue) {
            $envFilePath = Join-Path $repoRoot '.env'
            if (Test-Path -LiteralPath $envFilePath) {
                Load-EnvFile -EnvFilePath $envFilePath -ErrorAction SilentlyContinue
            }
        }
    }
}
catch {
    # Silently fail - .env loading shouldn't block script execution
    # Environment variables may already be set from other sources
}

# Parse debug level once at script start (after .env is loaded)
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

try {
    # Import core modules first (needed by others)
    $corePath = Join-Path $libPath 'core'
    
    if ($debugLevel -ge 2) {
        Write-Host "  [build-fragment-cache] Importing core modules from: $corePath" -ForegroundColor DarkGray
    }
    
    # Import CommonEnums FIRST with -Global -Force to ensure enums are available globally
    # This is needed because Validation.psm1 (imported by SafeImport.psm1, imported by Logging.psm1)
    # uses FileSystemPathType in parameter definitions, which requires the type at parse time
    $commonEnumsPath = Join-Path $corePath 'CommonEnums.psm1'
    if (Test-Path -LiteralPath $commonEnumsPath) {
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] Importing CommonEnums from: $commonEnumsPath" -ForegroundColor DarkGray
        }
        Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction Stop -Global -Force
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] ✓ CommonEnums imported successfully" -ForegroundColor DarkGray
        }
    }
    else {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] ⚠ CommonEnums module not found at: $commonEnumsPath" -ForegroundColor Yellow
        }
    }
    
    $exitCodesPath = Join-Path $corePath 'ExitCodes.psm1'
    if ($debugLevel -ge 3) {
        Write-Host "  [build-fragment-cache] Importing ExitCodes from: $exitCodesPath" -ForegroundColor DarkGray
    }
    Import-Module $exitCodesPath -DisableNameChecking -ErrorAction Stop -Global -Force
    if ($debugLevel -ge 3) {
        Write-Host "  [build-fragment-cache] ✓ ExitCodes imported successfully" -ForegroundColor DarkGray
    }
    
    # Logging.psm1 is optional - script works without it (uses fallback error/warning functions)
    # But if available, import it (CommonEnums is already loaded above)
    $loggingPath = Join-Path $corePath 'Logging.psm1'
    if (Test-Path -LiteralPath $loggingPath) {
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] Importing Logging from: $loggingPath" -ForegroundColor DarkGray
        }
        Import-Module $loggingPath -DisableNameChecking -ErrorAction SilentlyContinue -Global -Force
        if ($debugLevel -ge 3) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-Host "  [build-fragment-cache] ✓ Logging imported successfully (structured logging available)" -ForegroundColor DarkGray
            }
            else {
                Write-Host "  [build-fragment-cache] ⚠ Logging imported but structured functions not available" -ForegroundColor Yellow
            }
        }
    }
    else {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] ⚠ Logging module not found, using fallback error/warning functions" -ForegroundColor Yellow
        }
    }
    
    if ($debugLevel -ge 2) {
        Write-Host "  [build-fragment-cache] ✓ Core modules imported successfully" -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to import required modules: $_"
    if ($debugLevel -ge 2) {
        Write-Host "  [build-fragment-cache] ✗ Module import failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] Error type: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
            Write-Host "  [build-fragment-cache] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
    }
    exit 1
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Host "  [build-fragment-cache] Starting fragment cache building operation" -ForegroundColor DarkGray
}

Write-Host "`nBuilding Fragment Cache" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

# Statistics tracking
$stats = @{
    FragmentsDiscovered = 0
    FragmentsParsed = 0
    FragmentsFailed = 0
    CommandsRegistered = 0
    CommandsDiscovered = 0
    CacheInitialized = $false
    CacheInitializationFailed = $false
}

# Helper function to handle errors consistently
function Write-CacheOperationError {
    param(
        [string]$OperationName,
        [string]$ErrorMessage,
        [string]$ErrorType,
        [hashtable]$Context = @{}
    )
    
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object System.Exception($ErrorMessage)),
            "CacheOperationFailed",
            [System.Management.Automation.ErrorCategory]::OperationStopped,
            $null
        )
        Write-StructuredError -ErrorRecord $errorRecord -OperationName "build-fragment-cache.$OperationName" -Context $Context -StatusCode 500
    }
    else {
        Write-Host "  ✗ $OperationName failed: $ErrorMessage" -ForegroundColor Red
        if ($debugLevel -ge 2) {
            Write-Host "    [build-fragment-cache] Error type: $ErrorType" -ForegroundColor DarkGray
        }
    }
}

# Helper function to handle warnings consistently
function Write-CacheOperationWarning {
    param(
        [string]$Message,
        [hashtable]$Context = @{}
    )
    
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        Write-StructuredWarning -Message $Message -OperationName 'build-fragment-cache' -Context $Context -Code 'CacheOperationWarning'
    }
    else {
        Write-Host "  ⚠ $Message" -ForegroundColor Yellow
    }
}

# Discover fragment files
$fragmentFiles = @()
if ($PSCmdlet.ShouldProcess('Fragment discovery', 'Discover fragment files')) {
    try {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Starting fragment discovery..." -ForegroundColor DarkGray
        }
        
        if ($FragmentPath) {
            $profileDPath = $FragmentPath
            if ($debugLevel -ge 2) {
                Write-Host "  [build-fragment-cache] Using provided fragment path: $profileDPath" -ForegroundColor DarkGray
            }
        }
        else {
            # Try to discover profile.d from repository root
            # Calculate repo root: scripts/utils -> scripts -> repo root
            $repoRoot = Split-Path -Parent $scriptsDir
            $profileDPath = Join-Path $repoRoot 'profile.d'
            if ($debugLevel -ge 2) {
                Write-Host "  [build-fragment-cache] Auto-discovering profile.d from repository root: $repoRoot" -ForegroundColor DarkGray
            }
        }
        
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] Checking fragment directory: $profileDPath" -ForegroundColor DarkGray
        }
        
        if (-not (Test-Path -LiteralPath $profileDPath)) {
            Write-CacheOperationError -OperationName "Fragment discovery" -ErrorMessage "profile.d directory not found: $profileDPath" -ErrorType "DirectoryNotFound" -Context @{
                profile_d_path = $profileDPath
            }
            Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
        }
        
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Fragment directory found, scanning for .ps1 files..." -ForegroundColor DarkGray
        }
        
        # Discover fragment files (exclude test files)
        $allFragmentFiles = Get-ChildItem -Path $profileDPath -File -Filter '*.ps1' -ErrorAction Stop
        $testModeEnabled = if ($env:PS_PROFILE_TEST_MODE) { $true } else { $false }
        
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] Found $($allFragmentFiles.Count) total .ps1 file(s), test mode: $testModeEnabled" -ForegroundColor DarkGray
        }
        
        $fragmentFiles = $allFragmentFiles |
            Where-Object {
                if ($testModeEnabled) {
                    $true
                }
                else {
                    $_.BaseName -notmatch '-test-'
                }
            }
        
        $stats.FragmentsDiscovered = $fragmentFiles.Count
        
        Write-Host "  ✓ Discovered $($stats.FragmentsDiscovered) fragment file(s) in: $profileDPath" -ForegroundColor Green
        
        if ($debugLevel -ge 2) {
            Write-Host "    [build-fragment-cache] Fragment directory: $profileDPath" -ForegroundColor DarkGray
            if ($allFragmentFiles.Count -ne $fragmentFiles.Count) {
                $excludedCount = $allFragmentFiles.Count - $fragmentFiles.Count
                Write-Host "    [build-fragment-cache] Excluded $excludedCount test fragment(s)" -ForegroundColor DarkGray
            }
        }
        
        if ($debugLevel -ge 3 -and $fragmentFiles.Count -gt 0) {
            Write-Host "    [build-fragment-cache] Fragment files:" -ForegroundColor DarkGray
            foreach ($fragment in $fragmentFiles) {
                Write-Host "      [build-fragment-cache]   - $($fragment.BaseName)" -ForegroundColor DarkGray
            }
        }
    }
    catch {
        Write-CacheOperationError -OperationName "Fragment discovery" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName -Context @{
            profile_d_path = $profileDPath
        }
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] ✗ Fragment discovery failed: $($_.Exception.Message)" -ForegroundColor Red
            if ($debugLevel -ge 3) {
                Write-Host "  [build-fragment-cache] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
        }
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
    }
}
else {
    Write-Host "  [WhatIf] Would discover fragment files from: $profileDPath" -ForegroundColor Cyan
}

if ($fragmentFiles.Count -eq 0) {
    Write-CacheOperationWarning -Message "No fragment files found to build cache" -Context @{
        profile_d_path = $profileDPath
    }
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE
}

# Initialize fragment cache
if ($PSCmdlet.ShouldProcess('Fragment cache initialization', 'Initialize cache system')) {
    try {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Starting cache initialization..." -ForegroundColor DarkGray
        }
        
        $fragmentCacheInitPath = Join-Path $scriptsDir 'lib' 'fragment' 'FragmentCacheInitialization.psm1'
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] FragmentCacheInitialization module path: $fragmentCacheInitPath" -ForegroundColor DarkGray
        }
        
        if (Test-Path -LiteralPath $fragmentCacheInitPath) {
            if ($debugLevel -ge 3) {
                Write-Host "  [build-fragment-cache] Importing FragmentCacheInitialization module..." -ForegroundColor DarkGray
            }
            Import-Module $fragmentCacheInitPath -DisableNameChecking -ErrorAction Stop -Force
            
            if ($debugLevel -ge 3) {
                Write-Host "  [build-fragment-cache] ✓ FragmentCacheInitialization module imported" -ForegroundColor DarkGray
            }
            
            if (Get-Command Initialize-FragmentCache -ErrorAction SilentlyContinue) {
                # Check if AST parsing is enabled (if not explicitly provided)
                if (-not $PSBoundParameters.ContainsKey('UseAstParsing')) {
                    if ($env:PS_PROFILE_USE_AST_PARSING) {
                        $normalized = $env:PS_PROFILE_USE_AST_PARSING.Trim().ToLowerInvariant()
                        $UseAstParsing = ($normalized -eq '1' -or $normalized -eq 'true')
                    }
                }
                
                if ($debugLevel -ge 2) {
                    Write-Host "  [build-fragment-cache] Configuration:" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   AST parsing: $UseAstParsing" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   Fragments to initialize: $($fragmentFiles.Count)" -ForegroundColor DarkGray
                }
                
                # Check SQLite availability before initialization
                if ($debugLevel -ge 3) {
                    if (Get-Command Test-SqliteAvailable -ErrorAction SilentlyContinue) {
                        $sqliteAvailable = Test-SqliteAvailable
                        Write-Host "  [build-fragment-cache] SQLite available: $sqliteAvailable" -ForegroundColor DarkGray
                        if ($sqliteAvailable -and (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue)) {
                            try {
                                $dbPath = Get-FragmentCacheDbPath
                                Write-Host "  [build-fragment-cache] Cache database path: $dbPath" -ForegroundColor DarkGray
                            }
                            catch {
                                Write-Host "  [build-fragment-cache] Could not determine database path: $($_.Exception.Message)" -ForegroundColor Yellow
                            }
                        }
                    }
                }
                
                $initStartTime = Get-Date
                $cacheInitialized = Initialize-FragmentCache -FragmentFiles $fragmentFiles -UseAstParsing $UseAstParsing
                $initDuration = ((Get-Date) - $initStartTime).TotalMilliseconds
                
                if ($cacheInitialized) {
                    $stats.CacheInitialized = $true
                    Write-Host "  ✓ Fragment cache initialized" -ForegroundColor Green
                    if ($debugLevel -ge 2) {
                        Write-Host "    [build-fragment-cache] Cache initialization completed successfully in $([Math]::Round($initDuration, 0))ms" -ForegroundColor DarkGray
                    }
                    if ($debugLevel -ge 3) {
                        # Check cache state after initialization
                        if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
                            $contentCacheSize = $global:FragmentContentCache.Count
                            Write-Host "    [build-fragment-cache] FragmentContentCache entries: $contentCacheSize" -ForegroundColor DarkGray
                        }
                        if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
                            $astCacheSize = $global:FragmentAstCache.Count
                            Write-Host "    [build-fragment-cache] FragmentAstCache entries: $astCacheSize" -ForegroundColor DarkGray
                        }
                    }
                }
                else {
                    $stats.CacheInitializationFailed = $true
                    Write-CacheOperationWarning -Message "Fragment cache initialization returned false" -Context @{
                        use_ast_parsing = $UseAstParsing
                        init_duration_ms = [Math]::Round($initDuration, 0)
                    }
                    if ($debugLevel -ge 2) {
                        Write-Host "    [build-fragment-cache] ⚠ Cache initialization returned false (duration: $([Math]::Round($initDuration, 0))ms)" -ForegroundColor Yellow
                    }
                }
            }
            else {
                Write-CacheOperationError -OperationName "Cache initialization" -ErrorMessage "Initialize-FragmentCache function not found" -ErrorType "CommandNotFound" -Context @{
                    module_path = $fragmentCacheInitPath
                }
                if ($debugLevel -ge 2) {
                    Write-Host "  [build-fragment-cache] ✗ Initialize-FragmentCache function not found after module import" -ForegroundColor Red
                }
                Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
            }
        }
        else {
            Write-CacheOperationError -OperationName "Cache initialization" -ErrorMessage "FragmentCacheInitialization module not found" -ErrorType "FileNotFound" -Context @{
                module_path = $fragmentCacheInitPath
            }
            if ($debugLevel -ge 2) {
                Write-Host "  [build-fragment-cache] ✗ FragmentCacheInitialization module not found at: $fragmentCacheInitPath" -ForegroundColor Red
            }
            Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
        }
    }
    catch {
        $stats.CacheInitializationFailed = $true
        Write-CacheOperationError -OperationName "Cache initialization" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName -Context @{
            module_path = $fragmentCacheInitPath
        }
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] ✗ Cache initialization failed: $($_.Exception.Message)" -ForegroundColor Red
            if ($debugLevel -ge 3) {
                Write-Host "  [build-fragment-cache] Error type: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
                Write-Host "  [build-fragment-cache] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
        }
        if (-not $Force) {
            Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
        }
    }
}
else {
    Write-Host "  [WhatIf] Would initialize fragment cache system" -ForegroundColor Cyan
}

# Parse all fragments to build cache
if ($PSCmdlet.ShouldProcess('Fragment parsing', 'Parse fragments to build cache')) {
    try {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Starting fragment parsing..." -ForegroundColor DarkGray
        }
        
        $parserModulePath = Join-Path $scriptsDir 'lib' 'fragment' 'FragmentCommandParserOrchestration.psm1'
        if ($debugLevel -ge 3) {
            Write-Host "  [build-fragment-cache] FragmentCommandParserOrchestration module path: $parserModulePath" -ForegroundColor DarkGray
        }
        
        if (Test-Path -LiteralPath $parserModulePath) {
            if ($debugLevel -ge 3) {
                Write-Host "  [build-fragment-cache] Importing FragmentCommandParserOrchestration module..." -ForegroundColor DarkGray
            }
            Import-Module $parserModulePath -DisableNameChecking -ErrorAction Stop -Force
            
            if ($debugLevel -ge 3) {
                Write-Host "  [build-fragment-cache] ✓ FragmentCommandParserOrchestration module imported" -ForegroundColor DarkGray
            }
            
            if (Get-Command Register-AllFragmentCommands -ErrorAction SilentlyContinue) {
                Write-Host "  Parsing $($fragmentFiles.Count) fragment(s) to build cache..." -ForegroundColor Cyan
                
                # Check parsing configuration and provide recommendations
                if ($debugLevel -ge 2) {
                    Write-Host "    [build-fragment-cache] Parsing configuration:" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   ✓ Using BOTH AST and regex parsing for maximum command discovery (default behavior)" -ForegroundColor Green
                    Write-Host "    [build-fragment-cache]   Both parsing modes will be cached separately in the database" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   Note: PS_PROFILE_USE_AST_PARSING is deprecated - we always use both modes" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache] Starting batch parsing operation..." -ForegroundColor DarkGray
                }
                
                # Show progress indicator for long-running operations
                $showProgress = $fragmentFiles.Count -gt 10
                if ($showProgress) {
                    Write-Progress -Activity "Building Fragment Cache" -Status "Parsing fragments..." -PercentComplete 0
                }
                
                $parseStartTime = Get-Date
                try {
                    # Force both AST and regex parsing to ensure maximum command discovery
                    # This caches both parsing modes separately in the database
                    $parseStats = Register-AllFragmentCommands -FragmentFiles $fragmentFiles -ForceBothParsingModes
                }
                finally {
                    if ($showProgress) {
                        Write-Progress -Activity "Building Fragment Cache" -Completed
                    }
                }
                $parseDuration = ((Get-Date) - $parseStartTime).TotalMilliseconds
                
                # Update statistics
                $stats.FragmentsParsed = if ($parseStats.ParsedFragments) { $parseStats.ParsedFragments } else { 0 }
                $stats.FragmentsFailed = if ($parseStats.FailedFragments) { $parseStats.FailedFragments } else { 0 }
                $stats.CommandsRegistered = if ($parseStats.RegisteredCommands) { $parseStats.RegisteredCommands } else { 0 }
                $stats.CommandsDiscovered = if ($parseStats.DiscoveredCommands) { $parseStats.DiscoveredCommands } else { 0 }
                
                # Format duration for readability
                $parseDurationSeconds = [Math]::Round($parseDuration / 1000, 2)
                $parseDurationFormatted = if ($parseDuration -gt 60000) {
                    "$([Math]::Round($parseDurationSeconds / 60, 1)) minutes ($([Math]::Round($parseDuration, 0))ms)"
                }
                elseif ($parseDuration -gt 1000) {
                    "$parseDurationSeconds seconds ($([Math]::Round($parseDuration, 0))ms)"
                }
                else {
                    "$([Math]::Round($parseDuration, 0))ms"
                }
                
                Write-Host "  ✓ Parsed $($stats.FragmentsParsed) fragment(s) in $parseDurationFormatted" -ForegroundColor Green
                Write-Host "    Discovered: $($stats.CommandsDiscovered) command(s), Registered: $($stats.CommandsRegistered) command(s)" -ForegroundColor Gray
                Write-Host "    Note: Used both AST and regex parsing - both results cached separately in database" -ForegroundColor DarkGray
                
                # Performance analysis and recommendations
                $avgTimePerFragment = if ($stats.FragmentsParsed -gt 0) { [Math]::Round($parseDuration / $stats.FragmentsParsed, 2) } else { 0 }
                $totalSeconds = [Math]::Round($parseDuration / 1000, 2)
                
                # Performance warnings and recommendations
                if ($totalSeconds -gt 30) {
                    Write-Host ""
                    Write-Host "  ⚠ Performance Notice: Parsing took longer than expected" -ForegroundColor Yellow
                    Write-Host "    [build-fragment-cache] Average time per fragment: ${avgTimePerFragment}ms" -ForegroundColor Yellow
                    
                    # Parsing mode information
                    Write-Host "    [build-fragment-cache] ℹ Using both AST and regex parsing (ForceBothParsingModes enabled)" -ForegroundColor Cyan
                    Write-Host "    [build-fragment-cache]      Both parsing modes are cached separately in the database" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]      This ensures maximum command discovery during cache warming" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]      AST finds function definitions, regex finds Set-AgentMode* calls" -ForegroundColor DarkGray
                    
                    # High average time recommendations
                    if ($avgTimePerFragment -gt 1000) {
                        Write-Host "    [build-fragment-cache] 💡 High average time detected (${avgTimePerFragment}ms per fragment)" -ForegroundColor Cyan
                        Write-Host "    [build-fragment-cache]      Possible causes:" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]        • Large fragment files (>100KB)" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]        • SQLite database write operations (first build)" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]        • Complex regex patterns or many commands per fragment" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]      To investigate:" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]        • Run with PS_PROFILE_DEBUG=3 to see per-fragment timing" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]        • Check fragment file sizes: Get-ChildItem profile.d\*.ps1 | Sort-Object Length -Descending | Select-Object -First 10" -ForegroundColor DarkGray
                    }
                    elseif ($avgTimePerFragment -gt 500) {
                        Write-Host "    [build-fragment-cache] 💡 Moderate average time (${avgTimePerFragment}ms per fragment)" -ForegroundColor Cyan
                        Write-Host "    [build-fragment-cache]      This is acceptable but could be optimized" -ForegroundColor DarkGray
                    }
                    
                    # Check cache hit rates
                    # Cache hit rate calculation: Since we have 2 cache types (AST and Content),
                    # the maximum possible hits is FragmentsParsed * 2 (one AST hit + one Content hit per fragment)
                    $cacheHitRate = 0
                    if ($parseStats.AstCacheHits -or $parseStats.ContentCacheHits) {
                        $totalCacheHits = ($parseStats.AstCacheHits ?? 0) + ($parseStats.ContentCacheHits ?? 0)
                        $maxPossibleHits = if ($stats.FragmentsParsed -gt 0) { $stats.FragmentsParsed * 2 } else { 1 }
                        $cacheHitRate = [Math]::Round(($totalCacheHits / $maxPossibleHits) * 100, 1)
                        
                        if ($cacheHitRate -lt 10) {
                            Write-Host "    [build-fragment-cache] 💡 Cache hit rate: ${cacheHitRate}% (low - this is expected for first build)" -ForegroundColor Cyan
                            Write-Host "    [build-fragment-cache]      Subsequent builds will be faster as cache entries are populated" -ForegroundColor DarkGray
                            Write-Host "    [build-fragment-cache]      Expected improvement: 50-90% faster on next build" -ForegroundColor DarkGray
                        }
                        elseif ($cacheHitRate -lt 50) {
                            Write-Host "    [build-fragment-cache] 💡 Cache hit rate: ${cacheHitRate}% (moderate)" -ForegroundColor Cyan
                            Write-Host "    [build-fragment-cache]      Some fragments were cached, but many needed re-parsing" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        Write-Host "    [build-fragment-cache] 💡 No cache hits (0%) - this is expected for first build" -ForegroundColor Cyan
                        Write-Host "    [build-fragment-cache]      All fragments were parsed and cached for the first time" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]      Next build should be significantly faster" -ForegroundColor DarkGray
                    }
                    
                    # SQLite performance note
                    if ($stats.CacheInitialized) {
                        Write-Host "    [build-fragment-cache] ℹ Note: First build includes SQLite database writes" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]      Subsequent builds will primarily read from cache" -ForegroundColor DarkGray
                    }
                }
                
                if ($stats.FragmentsFailed -gt 0) {
                    Write-CacheOperationWarning -Message "$($stats.FragmentsFailed) fragment(s) failed to parse" -Context @{
                        failed_count = $stats.FragmentsFailed
                        total_fragments = $fragmentFiles.Count
                    }
                }
                
                if ($debugLevel -ge 2) {
                    Write-Host ""
                    Write-Host "  [build-fragment-cache] Detailed statistics:" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   Fragments discovered: $($stats.FragmentsDiscovered)" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   Fragments parsed: $($stats.FragmentsParsed)" -ForegroundColor Green
                    if ($stats.FragmentsFailed -gt 0) {
                        Write-Host "    [build-fragment-cache]   Fragments failed: $($stats.FragmentsFailed)" -ForegroundColor Red
                    }
                    Write-Host "    [build-fragment-cache]   Commands discovered: $($stats.CommandsDiscovered)" -ForegroundColor Blue
                    Write-Host "    [build-fragment-cache]   Commands registered: $($stats.CommandsRegistered)" -ForegroundColor Blue
                    
                    # Cache hit statistics
                    $totalCacheHits = ($parseStats.AstCacheHits ?? 0) + ($parseStats.ContentCacheHits ?? 0)
                    if ($parseStats.AstCacheHits) {
                        Write-Host "    [build-fragment-cache]   AST cache hits: $($parseStats.AstCacheHits)" -ForegroundColor Blue
                    }
                    if ($parseStats.ContentCacheHits) {
                        Write-Host "    [build-fragment-cache]   Content cache hits: $($parseStats.ContentCacheHits)" -ForegroundColor Blue
                    }
                    if ($totalCacheHits -gt 0 -and $stats.FragmentsParsed -gt 0) {
                        # Cache hit rate: total hits / (fragments * 2 cache types) * 100
                        $maxPossibleHits = $stats.FragmentsParsed * 2
                        $cacheHitRate = [Math]::Round(($totalCacheHits / $maxPossibleHits) * 100, 1)
                        Write-Host "    [build-fragment-cache]   Cache hit rate: ${cacheHitRate}%" -ForegroundColor Blue
                    }
                    
                    # Performance breakdown
                    Write-Host "    [build-fragment-cache]   Parse duration: $parseDurationFormatted" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   Average time per fragment: ${avgTimePerFragment}ms" -ForegroundColor DarkGray
                    
                    # Performance categorization
                    $performanceCategory = if ($avgTimePerFragment -lt 50) {
                        "Excellent"
                    }
                    elseif ($avgTimePerFragment -lt 200) {
                        "Good"
                    }
                    elseif ($avgTimePerFragment -lt 500) {
                        "Fair"
                    }
                    elseif ($avgTimePerFragment -lt 1000) {
                        "Slow"
                    }
                    else {
                        "Very Slow"
                    }
                    $perfColor = switch ($performanceCategory) {
                        "Excellent" { "Green" }
                        "Good" { "Green" }
                        "Fair" { "Yellow" }
                        "Slow" { "Yellow" }
                        "Very Slow" { "Red" }
                    }
                    Write-Host "    [build-fragment-cache]   Performance category: $performanceCategory" -ForegroundColor $perfColor
                    
                    # Commands per fragment ratio
                    if ($stats.FragmentsParsed -gt 0) {
                        $commandsPerFragment = [Math]::Round($stats.CommandsDiscovered / $stats.FragmentsParsed, 2)
                        Write-Host "    [build-fragment-cache]   Commands per fragment: $commandsPerFragment" -ForegroundColor DarkGray
                    }
                }
                
                if ($debugLevel -ge 3) {
                    # Show cache state after parsing
                    Write-Host ""
                    Write-Host "  [build-fragment-cache] Cache state after parsing:" -ForegroundColor DarkGray
                    if (Get-Variable -Name 'FragmentContentCache' -Scope Global -ErrorAction SilentlyContinue) {
                        $contentCacheSize = $global:FragmentContentCache.Count
                        Write-Host "    [build-fragment-cache]   FragmentContentCache entries: $contentCacheSize" -ForegroundColor DarkGray
                    }
                    if (Get-Variable -Name 'FragmentAstCache' -Scope Global -ErrorAction SilentlyContinue) {
                        $astCacheSize = $global:FragmentAstCache.Count
                        Write-Host "    [build-fragment-cache]   FragmentAstCache entries: $astCacheSize" -ForegroundColor DarkGray
                    }
                    
                    # Check database state if available
                    if (Get-Command Get-FragmentCacheDbPath -ErrorAction SilentlyContinue) {
                        try {
                            $dbPath = Get-FragmentCacheDbPath
                            if ($dbPath -and (Test-Path -LiteralPath $dbPath)) {
                                $dbInfo = Get-Item -LiteralPath $dbPath -ErrorAction SilentlyContinue
                                if ($dbInfo) {
                                    $dbSizeKB = [Math]::Round($dbInfo.Length / 1KB, 2)
                                    $dbSizeMB = [Math]::Round($dbInfo.Length / 1MB, 2)
                                    $dbSizeFormatted = if ($dbSizeMB -ge 1) { "${dbSizeMB}MB (${dbSizeKB}KB)" } else { "${dbSizeKB}KB" }
                                    Write-Host "    [build-fragment-cache]   Database file size: $dbSizeFormatted" -ForegroundColor DarkGray
                                    Write-Host "    [build-fragment-cache]   Database path: $dbPath" -ForegroundColor DarkGray
                                }
                            }
                        }
                        catch {
                            # Ignore database path errors in debug output
                        }
                    }
                    
                    # Performance optimization suggestions
                    Write-Host ""
                    Write-Host "  [build-fragment-cache] Performance optimization suggestions:" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   ℹ Using both AST and regex parsing (ForceBothParsingModes)" -ForegroundColor Cyan
                    Write-Host "    [build-fragment-cache]      Both modes cached separately for maximum command discovery" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]      AST cache: ParsingMode='ast', Regex cache: ParsingMode='regex'" -ForegroundColor DarkGray
                    if ($avgTimePerFragment -gt 1000) {
                        Write-Host "    [build-fragment-cache]   ⚠ Very high average time per fragment (${avgTimePerFragment}ms)" -ForegroundColor Yellow
                        Write-Host "    [build-fragment-cache]      Investigate large fragment files:" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]        Get-ChildItem profile.d\*.ps1 | Sort-Object Length -Descending | Select-Object -First 5 Name, @{N='SizeKB';E={[Math]::Round(`$_.Length/1KB,1)}}" -ForegroundColor DarkGray
                    }
                    elseif ($avgTimePerFragment -gt 500) {
                        Write-Host "    [build-fragment-cache]   ⚠ High average time per fragment (${avgTimePerFragment}ms)" -ForegroundColor Yellow
                        Write-Host "    [build-fragment-cache]      Consider optimizing large or complex fragments" -ForegroundColor DarkGray
                    }
                    else {
                        Write-Host "    [build-fragment-cache]   ✓ Average time per fragment is acceptable (${avgTimePerFragment}ms)" -ForegroundColor Green
                    }
                    $totalCacheHitsForSuggestions = ($parseStats.AstCacheHits ?? 0) + ($parseStats.ContentCacheHits ?? 0)
                    if ($totalCacheHitsForSuggestions -eq 0 -and $stats.FragmentsParsed -gt 0) {
                        Write-Host "    [build-fragment-cache]   ℹ No cache hits - this is expected for first build" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]      Subsequent builds will benefit from cached entries" -ForegroundColor DarkGray
                        Write-Host "    [build-fragment-cache]      Expected speedup: 50-90% on next build" -ForegroundColor DarkGray
                    }
                    elseif ($totalCacheHitsForSuggestions -gt 0) {
                        # Cache hit rate: total hits / (fragments * 2 cache types) * 100
                        $maxPossibleHitsForSuggestions = $stats.FragmentsParsed * 2
                        $cacheHitRateForSuggestions = [Math]::Round(($totalCacheHitsForSuggestions / $maxPossibleHitsForSuggestions) * 100, 1)
                        Write-Host "    [build-fragment-cache]   ℹ Cache hit rate: ${cacheHitRateForSuggestions}%" -ForegroundColor DarkGray
                    }
                    Write-Host "    [build-fragment-cache]   ℹ Cache is now populated - profile loads will be faster" -ForegroundColor DarkGray
                    Write-Host "    [build-fragment-cache]   ℹ To rebuild cache: task clear-fragment-cache && task build-fragment-cache" -ForegroundColor DarkGray
                }
            }
            else {
                Write-CacheOperationError -OperationName "Fragment parsing" -ErrorMessage "Register-AllFragmentCommands function not found" -ErrorType "CommandNotFound" -Context @{
                    module_path = $parserModulePath
                }
                if ($debugLevel -ge 2) {
                    Write-Host "  [build-fragment-cache] ✗ Register-AllFragmentCommands function not found after module import" -ForegroundColor Red
                }
                Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
            }
        }
        else {
            Write-CacheOperationError -OperationName "Fragment parsing" -ErrorMessage "FragmentCommandParserOrchestration module not found" -ErrorType "FileNotFound" -Context @{
                module_path = $parserModulePath
            }
            if ($debugLevel -ge 2) {
                Write-Host "  [build-fragment-cache] ✗ FragmentCommandParserOrchestration module not found at: $parserModulePath" -ForegroundColor Red
            }
            Exit-WithCode -ExitCode $EXIT_SETUP_ERROR
        }
    }
    catch {
        Write-CacheOperationError -OperationName "Fragment parsing" -ErrorMessage $_.Exception.Message -ErrorType $_.Exception.GetType().FullName -Context @{
            fragment_count = $fragmentFiles.Count
        }
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] ✗ Fragment parsing failed: $($_.Exception.Message)" -ForegroundColor Red
            if ($debugLevel -ge 3) {
                Write-Host "  [build-fragment-cache] Error type: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
                Write-Host "  [build-fragment-cache] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            }
        }
        if (-not $Force) {
            Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR
        }
    }
}
else {
    Write-Host "  [WhatIf] Would parse $($fragmentFiles.Count) fragment(s) to build cache" -ForegroundColor Cyan
}

# Summary
Write-Host ""
if ($PSCmdlet.ShouldProcess('Summary', 'Display summary')) {
    if ($debugLevel -ge 1) {
        Write-Host "  [build-fragment-cache] Generating summary..." -ForegroundColor DarkGray
    }
    
    if ($stats.FragmentsParsed -gt 0 -and $stats.FragmentsFailed -eq 0) {
        Write-Host "Fragment cache building completed successfully!" -ForegroundColor Green
    }
    elseif ($stats.FragmentsParsed -gt 0) {
        Write-Host "Fragment cache building completed with some failures" -ForegroundColor Yellow
    }
    else {
        Write-Host "Fragment cache building failed" -ForegroundColor Red
    }
    
    if ($debugLevel -ge 1) {
        Write-Host ""
        Write-Host "  [build-fragment-cache] Final summary:" -ForegroundColor DarkGray
        Write-Host "    [build-fragment-cache]   Cache initialized: $($stats.CacheInitialized)" -ForegroundColor $(if ($stats.CacheInitialized) { 'Green' } else { 'Red' })
        Write-Host "    [build-fragment-cache]   Fragments discovered: $($stats.FragmentsDiscovered)" -ForegroundColor DarkGray
        Write-Host "    [build-fragment-cache]   Fragments parsed: $($stats.FragmentsParsed)" -ForegroundColor $(if ($stats.FragmentsParsed -gt 0) { 'Green' } else { 'Red' })
        if ($stats.FragmentsFailed -gt 0) {
            Write-Host "    [build-fragment-cache]   Fragments failed: $($stats.FragmentsFailed)" -ForegroundColor Red
        }
        Write-Host "    [build-fragment-cache]   Commands discovered: $($stats.CommandsDiscovered)" -ForegroundColor Blue
        Write-Host "    [build-fragment-cache]   Commands registered: $($stats.CommandsRegistered)" -ForegroundColor Blue
    }
    
    # Exit with appropriate code
    # Use constants directly - PowerShell should convert int to enum automatically
    if ($stats.FragmentsFailed -gt 0 -and -not $Force) {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Exiting with error code due to $($stats.FragmentsFailed) failure(s)" -ForegroundColor DarkGray
        }
        Exit-WithCode -ExitCode $EXIT_OTHER_ERROR -Message "Cache building completed with $($stats.FragmentsFailed) failure(s)"
    }
    elseif ($stats.FragmentsParsed -eq 0 -and $stats.FragmentsDiscovered -gt 0) {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Exiting with error code: No fragments were successfully parsed" -ForegroundColor DarkGray
        }
        Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message "No fragments were successfully parsed"
    }
    elseif ($stats.CacheInitializationFailed -and -not $Force) {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Exiting with error code: Cache initialization failed" -ForegroundColor DarkGray
        }
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Cache initialization failed"
    }
    else {
        if ($debugLevel -ge 2) {
            Write-Host "  [build-fragment-cache] Exiting with success code" -ForegroundColor DarkGray
        }
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }
}
else {
    Write-Host ""
    Write-Host "[WhatIf] Summary: Would build cache for $($stats.FragmentsDiscovered) fragment(s)" -ForegroundColor Cyan
    if ($debugLevel -ge 2) {
        Write-Host "  [build-fragment-cache] [WhatIf] No actual cache building performed" -ForegroundColor DarkGray
    }
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
