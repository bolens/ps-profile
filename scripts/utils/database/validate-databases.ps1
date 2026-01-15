<#
.SYNOPSIS
    Validates SQLite database implementation and configuration.

.DESCRIPTION
    Performs comprehensive validation of SQLite database setup including:
    - SQLite availability
    - Cache directory accessibility
    - Database initialization
    - Corruption handling
    - Basic read/write operations

.PARAMETER TestOperations
    Also test basic read/write operations on databases.

.PARAMETER OutputFormat
    Output format: table, json. Defaults to table.

.EXAMPLE
    .\validate-databases.ps1
    Validates database setup without testing operations.

.EXAMPLE
    .\validate-databases.ps1 -TestOperations
    Validates setup and tests read/write operations.
#>

[CmdletBinding()]
param(
    [switch]$TestOperations,
    
    [OutputFormat]$OutputFormat = [OutputFormat]::Table
)

# Import required modules
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import CommonEnums for OutputFormat enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

# Import SQLite utilities
$sqliteModule = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'utilities' 'SqliteDatabase.psm1'
Import-Module $sqliteModule -DisableNameChecking -ErrorAction Stop

# Import database modules
$databaseModulesPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'database'
$commandHistoryModule = Join-Path $databaseModulesPath 'CommandHistoryDatabase.psm1'
$performanceMetricsModule = Join-Path $databaseModulesPath 'PerformanceMetricsDatabase.psm1'
$testCacheModule = Join-Path $databaseModulesPath 'TestCacheDatabase.psm1'

Import-Module $commandHistoryModule -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module $performanceMetricsModule -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module $testCacheModule -DisableNameChecking -ErrorAction SilentlyContinue

$validationResults = @{
    Timestamp              = Get-Date
    SqliteAvailable        = $false
    CacheDirectory         = $null
    CacheDirectoryWritable = $false
    Databases              = @()
    OverallStatus          = 'Unknown'
    Errors                 = @()
    Warnings               = @()
}

function Write-ValidationResult {
    param(
        [string]$Name,
        [bool]$Status,
        [string]$Message,
        [string]$Category = 'Info'
    )
    
    $result = @{
        Name     = $Name
        Status   = $Status
        Message  = $Message
        Category = $Category
    }
    
    if (-not $Status) {
        if ($Category -eq 'Error') {
            $validationResults.Errors += $Message
        }
        else {
            $validationResults.Warnings += $Message
        }
    }
    
    return $result
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[database.validate] Starting database validation"
    # Convert enum to string
    $outputFormatString = $OutputFormat.ToString()
    
    Write-Verbose "[database.validate] Test operations: $TestOperations, Output format: $outputFormatString"
}

try {
    Write-Host "`nValidating SQLite Database Implementation" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check SQLite availability
    Write-Host "Checking SQLite availability..." -ForegroundColor Yellow
    $sqliteAvailable = Test-SqliteAvailable
    $validationResults.SqliteAvailable = $sqliteAvailable
    
    if ($sqliteAvailable) {
        $sqliteCmd = Get-SqliteCommandName
        Write-Host "  ✓ SQLite available: $sqliteCmd" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ SQLite not available" -ForegroundColor Red
        Write-Host "    Install sqlite3: choco install sqlite -y (Windows) or brew install sqlite (macOS)" -ForegroundColor Gray
    }
    
    # Check cache directory
    Write-Host "`nChecking cache directory..." -ForegroundColor Yellow
    $cacheDir = Get-CacheDirectory
    $validationResults.CacheDirectory = $cacheDir
    
    if ($cacheDir) {
        Write-Host "  ✓ Cache directory: $cacheDir" -ForegroundColor Green
        
        # Check if directory exists and is writable
        if (-not (Test-Path -LiteralPath $cacheDir)) {
            try {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                Write-Host "  ✓ Created cache directory" -ForegroundColor Green
                $validationResults.CacheDirectoryWritable = $true
            }
            catch {
                Write-Host "  ✗ Cannot create cache directory: $($_.Exception.Message)" -ForegroundColor Red
                $validationResults.Errors += "Cannot create cache directory: $($_.Exception.Message)"
            }
        }
        else {
            # Test write access
            try {
                $testFile = Join-Path $cacheDir ".write-test"
                "test" | Out-File -LiteralPath $testFile -ErrorAction Stop
                Remove-Item -LiteralPath $testFile -ErrorAction Stop
                Write-Host "  ✓ Cache directory is writable" -ForegroundColor Green
                $validationResults.CacheDirectoryWritable = $true
            }
            catch {
                Write-Host "  ✗ Cache directory is not writable: $($_.Exception.Message)" -ForegroundColor Red
                $validationResults.Errors += "Cache directory is not writable: $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Host "  ✗ Cannot determine cache directory" -ForegroundColor Red
        $validationResults.Errors += "Cannot determine cache directory"
    }
    
    if (-not $sqliteAvailable) {
        Write-Host "`n⚠ SQLite is not available. Database features will use fallback storage." -ForegroundColor Yellow
        $validationResults.OverallStatus = 'Degraded'
        # Convert enum to string
        $outputFormatString = $OutputFormat.ToString()
        
        if ($outputFormatString -eq 'Json') {
            $validationResults | ConvertTo-Json -Depth 10
        }
        exit $EXIT_SUCCESS
    }
    
    # Level 1: Database validation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[database.validate] Starting individual database validation"
    }
    
    # Validate each database
    $databases = @(
        @{ Name = 'Command History'; Module = 'CommandHistoryDatabase'; PathFunc = 'Get-CommandHistoryDbPath'; InitFunc = 'Initialize-CommandHistoryDb' }
        @{ Name = 'Performance Metrics'; Module = 'PerformanceMetricsDatabase'; PathFunc = 'Get-PerformanceMetricsDbPath'; InitFunc = 'Initialize-PerformanceMetricsDb' }
        @{ Name = 'Test Cache'; Module = 'TestCacheDatabase'; PathFunc = 'Get-TestCacheDbPath'; InitFunc = 'Initialize-TestCacheDb' }
    )
    
    Write-Host "`nValidating databases..." -ForegroundColor Yellow
    
    $validationStartTime = Get-Date
    foreach ($db in $databases) {
        # Level 1: Individual database validation
        if ($debugLevel -ge 1) {
            Write-Verbose "[database.validate] Validating database: $($db.Name)"
        }
        
        $dbStartTime = Get-Date
        Write-Host "`n  $($db.Name):" -ForegroundColor White
        
        $dbResult = @{
            Name        = $db.Name
            Module      = $db.Module
            Path        = $null
            Exists      = $false
            Initialized = $false
            Integrity   = $false
            ReadTest    = $false
            WriteTest   = $false
            Errors      = @()
        }
        
        # Get database path
        try {
            $dbPath = & $db.PathFunc
            $dbResult.Path = $dbPath
            Write-Host "    Path: $dbPath" -ForegroundColor Gray
            
            if (Test-Path -LiteralPath $dbPath) {
                $dbResult.Exists = $true
                Write-Host "    ✓ Database file exists" -ForegroundColor Green
                
                # Check integrity
                $integrity = Test-DatabaseIntegrity -DatabasePath $dbPath
                $dbResult.Integrity = $integrity
                if ($integrity) {
                    Write-Host "    ✓ Database integrity check passed" -ForegroundColor Green
                }
                else {
                    Write-Host "    ✗ Database integrity check failed (corrupted)" -ForegroundColor Red
                    $dbResult.Errors += "Database integrity check failed"
                }
            }
            else {
                Write-Host "    ⚠ Database file does not exist (will be created on first use)" -ForegroundColor Yellow
            }
            
            # Test initialization
            try {
                $initResult = & $db.InitFunc
                $dbResult.Initialized = $initResult
                if ($initResult) {
                    Write-Host "    ✓ Database initialization successful" -ForegroundColor Green
                }
                else {
                    Write-Host "    ✗ Database initialization failed" -ForegroundColor Red
                    $dbResult.Errors += "Database initialization failed"
                }
            }
            catch {
                Write-Host "    ✗ Database initialization error: $($_.Exception.Message)" -ForegroundColor Red
                $dbResult.Errors += "Initialization error: $($_.Exception.Message)"
            }
            
            # Test operations if requested
            if ($TestOperations -and $dbResult.Initialized) {
                # Level 1: Operation testing start
                if ($debugLevel -ge 1) {
                    Write-Verbose "[database.validate] Testing operations for database: $($db.Name)"
                }
                
                Write-Host "    Testing operations..." -ForegroundColor Gray
                
                $opsStartTime = Get-Date
                switch ($db.Name) {
                    'Command History' {
                        try {
                            # Test write
                            $testResult = Add-CommandHistory -CommandLine "test-command-validation" -ExecutionTime 0.1 -ExitCode 0 -StartTime ([DateTimeOffset]::Now.ToUnixTimeMilliseconds()) -EndTime ([DateTimeOffset]::Now.ToUnixTimeMilliseconds())
                            if ($testResult) {
                                $dbResult.WriteTest = $true
                                Write-Host "      ✓ Write test passed" -ForegroundColor Green
                            }
                            
                            # Test read
                            $history = Get-CommandHistory -Limit 1
                            if ($history) {
                                $dbResult.ReadTest = $true
                                Write-Host "      ✓ Read test passed" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-Host "      ✗ Operation test failed: $($_.Exception.Message)" -ForegroundColor Red
                            $dbResult.Errors += "Operation test failed: $($_.Exception.Message)"
                        }
                    }
                    
                    'Performance Metrics' {
                        try {
                            # Test write
                            $testResult = Add-PerformanceMetric -MetricType 'validation' -MetricName 'test' -Value 1.0 -Unit 'ms'
                            if ($testResult) {
                                $dbResult.WriteTest = $true
                                Write-Host "      ✓ Write test passed" -ForegroundColor Green
                            }
                            
                            # Test read
                            $metrics = Get-PerformanceMetrics -MetricType 'validation' -Limit 1
                            if ($metrics) {
                                $dbResult.ReadTest = $true
                                Write-Host "      ✓ Read test passed" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-Host "      ✗ Operation test failed: $($_.Exception.Message)" -ForegroundColor Red
                            $dbResult.Errors += "Operation test failed: $($_.Exception.Message)"
                        }
                    }
                    
                    'Test Cache' {
                        try {
                            # Test write
                            $testResult = Save-TestCache -TestFilePath 'test-validation.tests.ps1' -TestResult (@{ Passed = 1 } | ConvertTo-Json) -ExecutionTime 0.1 -PassedCount 1 -FailedCount 0 -SkippedCount 0
                            if ($testResult) {
                                $dbResult.WriteTest = $true
                                Write-Host "      ✓ Write test passed" -ForegroundColor Green
                            }
                            
                            # Test read
                            $cached = Get-TestCache -TestFilePath 'test-validation.tests.ps1'
                            if ($cached) {
                                $dbResult.ReadTest = $true
                                Write-Host "      ✓ Read test passed" -ForegroundColor Green
                            }
                        }
                        catch {
                            Write-Host "      ✗ Operation test failed: $($_.Exception.Message)" -ForegroundColor Red
                            $dbResult.Errors += "Operation test failed: $($_.Exception.Message)"
                        }
                    }
                }
            }
            
            $validationResults.Databases += $dbResult
        }
        catch {
            Write-Host "    ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
            $dbResult.Errors += $_.Exception.Message
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'database.validate' -Context @{
                    database_name = $db.Name
                    database_module = $db.Module
                }
            }
            $validationResults.Databases += $dbResult
            # Continue processing other databases even if this one fails
        }
        
        $dbDuration = ((Get-Date) - $dbStartTime).TotalMilliseconds
        
        # Level 2: Individual database validation timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[database.validate] Database $($db.Name) validated in ${dbDuration}ms - Status: $($dbResult.Exists), Errors: $($dbResult.Errors.Count)"
        }
    }
    
    $validationDuration = ((Get-Date) - $validationStartTime).TotalMilliseconds
    
    # Level 2: Overall validation timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[database.validate] All databases validated in ${validationDuration}ms"
        Write-Verbose "[database.validate] Databases validated: $($validationResults.Databases.Count)"
    }
    
    # Level 3: Performance breakdown
    if ($debugLevel -ge 3) {
        Write-Host "  [database.validate] Performance - Validation: ${validationDuration}ms, Databases: $($validationResults.Databases.Count)" -ForegroundColor DarkGray
    }
    
    # Determine overall status
    $hasErrors = $validationResults.Errors.Count -gt 0
    $hasWarnings = $validationResults.Warnings.Count -gt 0
    $allDatabasesOk = ($validationResults.Databases | Where-Object { $_.Errors.Count -gt 0 }).Count -eq 0
    
    if ($hasErrors) {
        $validationResults.OverallStatus = 'Failed'
    }
    elseif ($hasWarnings -or -not $allDatabasesOk) {
        $validationResults.OverallStatus = 'Degraded'
    }
    else {
        $validationResults.OverallStatus = 'Success'
    }
    
    # Summary
    Write-Host "`nValidation Summary" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host "Overall Status: $($validationResults.OverallStatus)" -ForegroundColor $(switch ($validationResults.OverallStatus) {
            'Success' { 'Green' }
            'Degraded' { 'Yellow' }
            'Failed' { 'Red' }
            default { 'Gray' }
        })
    Write-Host "SQLite Available: $($validationResults.SqliteAvailable)" -ForegroundColor $(if ($validationResults.SqliteAvailable) { 'Green' } else { 'Yellow' })
    Write-Host "Cache Directory Writable: $($validationResults.CacheDirectoryWritable)" -ForegroundColor $(if ($validationResults.CacheDirectoryWritable) { 'Green' } else { 'Red' })
    Write-Host "Databases Validated: $($validationResults.Databases.Count)" -ForegroundColor Gray
    
    if ($validationResults.Errors.Count -gt 0) {
        Write-Host "`nErrors:" -ForegroundColor Red
        foreach ($error in $validationResults.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    
    if ($validationResults.Warnings.Count -gt 0) {
        Write-Host "`nWarnings:" -ForegroundColor Yellow
        foreach ($warning in $validationResults.Warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
    
    if ($OutputFormat -eq 'json') {
        Write-Host "`n"
        $validationResults | ConvertTo-Json -Depth 10
    }
    
    $exitCode = if ($validationResults.OverallStatus -eq 'Success') {
        $EXIT_SUCCESS
    }
    elseif ($validationResults.OverallStatus -eq 'Degraded') {
        $EXIT_VALIDATION_FAILURE
    }
    else {
        $EXIT_SETUP_ERROR
    }
    
    exit $exitCode
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'database.validate' -Context @{
            validation_phase = 'main'
        }
    }
    else {
        Write-Error "Validation failed: $($_.Exception.Message)"
        Write-Error $_.ScriptStackTrace
    }
    exit $EXIT_RUNTIME_ERROR
}
