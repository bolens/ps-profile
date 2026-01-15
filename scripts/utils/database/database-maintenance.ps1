<#
.SYNOPSIS
    Database maintenance and health check utility.

.DESCRIPTION
    Provides utilities for maintaining and monitoring SQLite databases used by the profile.
    Supports health checks, optimization, backup, and repair operations.

.PARAMETER Action
    Action to perform. Must be a DatabaseAction enum value.

.PARAMETER Database
    Specific database to operate on. If not specified, operates on all databases.

.PARAMETER OutputFormat
    Output format. Must be an OutputFormat enum value. Defaults to Table.

.EXAMPLE
    .\database-maintenance.ps1 -Action health
    Checks health of all databases.

.EXAMPLE
    .\database-maintenance.ps1 -Action optimize -Database "command-history"
    Optimizes the command history database.

.EXAMPLE
    .\database-maintenance.ps1 -Action statistics -OutputFormat json
    Gets statistics for all databases in JSON format.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [DatabaseAction]$Action,
    
    [string]$Database,
    
    [OutputFormat]$OutputFormat = [OutputFormat]::Table
)

# Import required modules
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import CommonEnums for DatabaseAction and OutputFormat enums
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import SQLite utilities
$sqliteModule = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'utilities' 'SqliteDatabase.psm1'
Import-Module $sqliteModule -DisableNameChecking -ErrorAction Stop

# Import database modules
$databaseModulesPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'database'
$commandHistoryModule = Join-Path $databaseModulesPath 'CommandHistoryDatabase.psm1'
$performanceMetricsModule = Join-Path $databaseModulesPath 'PerformanceMetricsDatabase.psm1'
$testCacheModule = Join-Path $databaseModulesPath 'TestCacheDatabase.psm1'

# Import modules to get path functions
Import-Module $commandHistoryModule -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module $performanceMetricsModule -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module $testCacheModule -DisableNameChecking -ErrorAction SilentlyContinue

$databases = @{
    'command-history'     = @{
        Name   = 'Command History'
        Path   = if (Get-Command Get-CommandHistoryDbPath -ErrorAction SilentlyContinue) { Get-CommandHistoryDbPath } else { Get-DatabasePath -DatabaseName 'command-history.db' }
        Module = $commandHistoryModule
    }
    'performance-metrics' = @{
        Name   = 'Performance Metrics'
        Path   = if (Get-Command Get-PerformanceMetricsDbPath -ErrorAction SilentlyContinue) { Get-PerformanceMetricsDbPath } else { Get-DatabasePath -DatabaseName 'performance-metrics.db' }
        Module = $performanceMetricsModule
    }
    'test-cache'          = @{
        Name   = 'Test Cache'
        Path   = if (Get-Command Get-TestCacheDbPath -ErrorAction SilentlyContinue) { Get-TestCacheDbPath } else { Get-DatabasePath -DatabaseName 'test-cache.db' }
        Module = $testCacheModule
    }
}

function Format-Size {
    param([long]$Size)
    
    if ($Size -lt 1KB) { return "$Size B" }
    if ($Size -lt 1MB) { return "$([math]::Round($Size / 1KB, 2)) KB" }
    if ($Size -lt 1GB) { return "$([math]::Round($Size / 1MB, 2)) MB" }
    return "$([math]::Round($Size / 1GB, 2)) GB"
}

function Show-HealthResults {
    param([object]$HealthResults)
    
    Write-Host "`nDatabase Health Check Results" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "SQLite Available: $($HealthResults.SqliteAvailable)" -ForegroundColor $(if ($HealthResults.SqliteAvailable) { 'Green' } else { 'Red' })
    Write-Host "Cache Directory: $($HealthResults.CacheDirectory)" -ForegroundColor Gray
    Write-Host "Total Size: $(Format-Size -Size $HealthResults.TotalSize)" -ForegroundColor Gray
    Write-Host "Healthy: $($HealthResults.HealthyCount) | Corrupted: $($HealthResults.CorruptedCount) | Missing: $($HealthResults.MissingCount)" -ForegroundColor Gray
    Write-Host ""
    
    foreach ($db in $HealthResults.Databases) {
        $status = if (-not $db.Exists) {
            [DatabaseStatus]::Missing
        }
        elseif (-not $db.Integrity) {
            [DatabaseStatus]::Corrupted
        }
        else {
            [DatabaseStatus]::Healthy
        }
        
        $color = switch ($status) {
            ([DatabaseStatus]::Healthy) { 'Green' }
            ([DatabaseStatus]::Corrupted) { 'Red' }
            ([DatabaseStatus]::Missing) { 'Yellow' }
        }
        
        Write-Host "  $($db.Name):" -ForegroundColor White
        Write-Host "    Status: $($status.ToString())" -ForegroundColor $color
        Write-Host "    Path: $($db.Path)" -ForegroundColor Gray
        Write-Host "    Size: $(Format-Size -Size $db.Size)" -ForegroundColor Gray
        
        if ($db.Statistics) {
            Write-Host "    Tables: $($db.Statistics.Tables.Count)" -ForegroundColor Gray
            Write-Host "    Total Rows: $($db.Statistics.TotalRows)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

try {
    # Level 1: Basic operation start
    if ($debugLevel -ge 1) {
        Write-Verbose "[database.maintenance] Starting database maintenance"
        Write-Verbose "[database.maintenance] Action: $Action, Database: $Database, Output format: $OutputFormat"
    }

    # Convert enums to strings
    $actionString = $Action.ToString()
    $outputFormatString = $OutputFormat.ToString()

    switch ($actionString) {
        'health' {
            $healthResults = Test-DatabaseHealth
            
            if ($outputFormatString -eq 'Json') {
                $healthResults | ConvertTo-Json -Depth 10
            }
            else {
                Show-HealthResults -HealthResults $healthResults
            }
        }
        
        'optimize' {
            $dbsToProcess = if ($Database) {
                if ($databases.ContainsKey($Database)) {
                    @($databases[$Database])
                }
                else {
                    $errorMsg = "Unknown database: $Database. Available: $($databases.Keys -join ', ')"
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            [System.ArgumentException]::new($errorMsg),
                            'UnknownDatabase',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $Database
                        )
                        Write-StructuredError -ErrorRecord $errorRecord -OperationName 'database.maintenance.validate' -Context @{
                            requested_database  = $Database
                            available_databases = $databases.Keys -join ','
                        }
                    }
                    else {
                        Write-Error $errorMsg
                    }
                    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure
                }
            }
            else {
                $databases.Values
            }
            
            $optimizeErrors = [System.Collections.Generic.List[string]]::new()
            foreach ($db in $dbsToProcess) {
                $dbPath = $db.Path
                if (-not (Test-Path -LiteralPath $dbPath)) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Database does not exist" -OperationName 'database.maintenance.optimize' -Context @{
                            database_name = $db.Name
                            database_path = $dbPath
                        } -Code 'DatabaseNotFound'
                    }
                    else {
                        Write-Warning "Database does not exist: $dbPath"
                    }
                    continue
                }
                
                Write-Host "Optimizing $($db.Name)..." -ForegroundColor Cyan
                try {
                    if (Optimize-Database -DatabasePath $dbPath -ErrorAction Stop) {
                        Write-Host "  ✓ Optimized successfully" -ForegroundColor Green
                    }
                    else {
                        Write-Host "  ✗ Optimization failed" -ForegroundColor Red
                        $optimizeErrors.Add($db.Name)
                    }
                }
                catch {
                    $optimizeErrors.Add($db.Name)
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'database.maintenance.optimize' -Context @{
                            database_name = $db.Name
                            database_path = $dbPath
                        }
                    }
                    else {
                        Write-Host "  ✗ Optimization error: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            if ($optimizeErrors.Count -gt 0) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Some databases failed to optimize" -OperationName 'database.maintenance.optimize' -Context @{
                        failed_databases = $optimizeErrors -join ','
                        failed_count     = $optimizeErrors.Count
                    } -Code 'OptimizePartialFailure'
                }
            }
        }
        
        'backup' {
            $dbsToProcess = if ($Database) {
                if ($databases.ContainsKey($Database)) {
                    @($databases[$Database])
                }
                else {
                    $errorMsg = "Unknown database: $Database. Available: $($databases.Keys -join ', ')"
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            [System.ArgumentException]::new($errorMsg),
                            'UnknownDatabase',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $Database
                        )
                        Write-StructuredError -ErrorRecord $errorRecord -OperationName 'database.maintenance.validate' -Context @{
                            requested_database  = $Database
                            available_databases = $databases.Keys -join ','
                        }
                    }
                    else {
                        Write-Error $errorMsg
                    }
                    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure
                }
            }
            else {
                $databases.Values
            }
            
            $backupErrors = [System.Collections.Generic.List[string]]::new()
            foreach ($db in $dbsToProcess) {
                $dbPath = $db.Path
                if (-not (Test-Path -LiteralPath $dbPath)) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Database does not exist" -OperationName 'database.maintenance.backup' -Context @{
                            database_name = $db.Name
                            database_path = $dbPath
                        } -Code 'DatabaseNotFound'
                    }
                    else {
                        Write-Warning "Database does not exist: $dbPath"
                    }
                    continue
                }
                
                Write-Host "Backing up $($db.Name)..." -ForegroundColor Cyan
                try {
                    $backupPath = Backup-Database -DatabasePath $dbPath -ErrorAction Stop
                    if ($backupPath) {
                        Write-Host "  ✓ Backup created: $backupPath" -ForegroundColor Green
                    }
                    else {
                        Write-Host "  ✗ Backup failed" -ForegroundColor Red
                        $backupErrors.Add($db.Name)
                    }
                }
                catch {
                    $backupErrors.Add($db.Name)
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'database.maintenance.backup' -Context @{
                            database_name = $db.Name
                            database_path = $dbPath
                        }
                    }
                    else {
                        Write-Host "  ✗ Backup error: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            if ($backupErrors.Count -gt 0) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Some databases failed to backup" -OperationName 'database.maintenance.backup' -Context @{
                        failed_databases = $backupErrors -join ','
                        failed_count     = $backupErrors.Count
                    } -Code 'BackupPartialFailure'
                }
            }
        }
        
        'repair' {
            $dbsToProcess = if ($Database) {
                if ($databases.ContainsKey($Database)) {
                    @($databases[$Database])
                }
                else {
                    $errorMsg = "Unknown database: $Database. Available: $($databases.Keys -join ', ')"
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            [System.ArgumentException]::new($errorMsg),
                            'UnknownDatabase',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $Database
                        )
                        Write-StructuredError -ErrorRecord $errorRecord -OperationName 'database.maintenance.validate' -Context @{
                            requested_database  = $Database
                            available_databases = $databases.Keys -join ','
                        }
                    }
                    else {
                        Write-Error $errorMsg
                    }
                    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure
                }
            }
            else {
                $databases.Values
            }
            
            $repairErrors = [System.Collections.Generic.List[string]]::new()
            foreach ($db in $dbsToProcess) {
                $dbPath = $db.Path
                if (-not (Test-Path -LiteralPath $dbPath)) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Database does not exist" -OperationName 'database.maintenance.repair' -Context @{
                            database_name = $db.Name
                            database_path = $dbPath
                        } -Code 'DatabaseNotFound'
                    }
                    else {
                        Write-Warning "Database does not exist: $dbPath"
                    }
                    continue
                }
                
                Write-Host "Repairing $($db.Name)..." -ForegroundColor Cyan
                try {
                    if (Repair-Database -DatabasePath $dbPath -BackupBeforeRepair -ErrorAction Stop) {
                        Write-Host "  ✓ Repaired successfully" -ForegroundColor Green
                    }
                    else {
                        Write-Host "  ✗ Repair failed" -ForegroundColor Red
                        $repairErrors.Add($db.Name)
                    }
                }
                catch {
                    $repairErrors.Add($db.Name)
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'database.maintenance.repair' -Context @{
                            database_name = $db.Name
                            database_path = $dbPath
                        }
                    }
                    else {
                        Write-Host "  ✗ Repair error: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            if ($repairErrors.Count -gt 0) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Some databases failed to repair" -OperationName 'database.maintenance.repair' -Context @{
                        failed_databases = $repairErrors -join ','
                        failed_count     = $repairErrors.Count
                    } -Code 'RepairPartialFailure'
                }
            }
        }
        
        'statistics' {
            $dbsToProcess = if ($Database) {
                if ($databases.ContainsKey($Database)) {
                    @($databases[$Database])
                }
                else {
                    $errorMsg = "Unknown database: $Database. Available: $($databases.Keys -join ', ')"
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            [System.ArgumentException]::new($errorMsg),
                            'UnknownDatabase',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $Database
                        )
                        Write-StructuredError -ErrorRecord $errorRecord -OperationName 'database.maintenance.validate' -Context @{
                            requested_database  = $Database
                            available_databases = $databases.Keys -join ','
                        }
                    }
                    else {
                        Write-Error $errorMsg
                    }
                    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure
                }
            }
            else {
                $databases.Values
            }
            
            $allStats = @()
            $statsErrors = [System.Collections.Generic.List[string]]::new()
            foreach ($db in $dbsToProcess) {
                $dbPath = $db.Path
                if (-not (Test-Path -LiteralPath $dbPath)) {
                    continue
                }
                
                try {
                    $stats = Get-DatabaseStatistics -DatabasePath $dbPath -ErrorAction Stop
                    if ($stats) {
                        $allStats += @{
                            Name       = $db.Name
                            Statistics = $stats
                        }
                    }
                }
                catch {
                    $statsErrors.Add($db.Name)
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'database.maintenance.statistics' -Context @{
                            database_name = $db.Name
                            database_path = $dbPath
                        }
                    }
                    else {
                        Write-ScriptMessage -Message "Failed to get statistics for $($db.Name): $($_.Exception.Message)" -IsWarning
                    }
                }
            }
            if ($statsErrors.Count -gt 0) {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Some databases failed to get statistics" -OperationName 'database.maintenance.statistics' -Context @{
                        failed_databases = $statsErrors -join ','
                        failed_count     = $statsErrors.Count
                    } -Code 'StatisticsPartialFailure'
                }
            }
            
            if ($outputFormatString -eq 'Json') {
                $allStats | ConvertTo-Json -Depth 10
            }
            else {
                foreach ($item in $allStats) {
                    Write-Host "`n$($item.Name) Statistics" -ForegroundColor Cyan
                    Write-Host "=========================" -ForegroundColor Cyan
                    Write-Host "Path: $($item.Statistics.Path)" -ForegroundColor Gray
                    Write-Host "Size: $(Format-Size -Size $item.Statistics.Size)" -ForegroundColor Gray
                    Write-Host "Integrity: $($item.Statistics.Integrity)" -ForegroundColor $(if ($item.Statistics.Integrity) { 'Green' } else { 'Red' })
                    Write-Host "Total Rows: $($item.Statistics.TotalRows)" -ForegroundColor Gray
                    Write-Host "Last Modified: $($item.Statistics.LastModified)" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "Tables:" -ForegroundColor White
                    foreach ($table in $item.Statistics.Tables) {
                        Write-Host "  $($table.Name): $($table.RowCount) rows" -ForegroundColor Gray
                    }
                    Write-Host ""
                }
            }
        }
    }
    
    Exit-WithCode -ExitCode [ExitCode]::Success
}
catch {
    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
        Write-StructuredError -ErrorRecord $_ -OperationName 'database.maintenance' -Context @{
            action   = $actionString
            database = $Database
        }
    }
    else {
        Write-Error "Error: $($_.Exception.Message)"
    }
    Exit-WithCode -ExitCode [ExitCode]::OtherError
}
