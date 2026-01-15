# ===============================================
# database.ps1
# Database client tools and helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: server, development

<#
.SYNOPSIS
    Database client tools and helper functions.

.DESCRIPTION
    Provides PowerShell functions and aliases for common database client operations.
    Supports MongoDB Compass, SQL Workbench, DBeaver, TablePlus, Hasura CLI, and Supabase CLI.
    Functions check for tool availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Database
    Author: PowerShell Profile
#>

# MongoDB Compass - launch MongoDB GUI
<#
.SYNOPSIS
    Launches MongoDB Compass GUI.

.DESCRIPTION
    Opens MongoDB Compass, a GUI tool for MongoDB database management.

.EXAMPLE
    Invoke-MongoDbCompass
#>
function Invoke-MongoDbCompass {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand mongodb-compass) {
        mongodb-compass
    }
    else {
        Write-MissingToolWarning -Tool 'mongodb-compass' -InstallHint 'Install with: scoop install mongodb-compass'
    }
}

# SQL Workbench - launch SQL Workbench/J
<#
.SYNOPSIS
    Launches SQL Workbench/J.

.DESCRIPTION
    Opens SQL Workbench/J, a universal database tool for SQL databases.

.EXAMPLE
    Invoke-SqlWorkbench
#>
function Invoke-SqlWorkbench {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand sql-workbench) {
        sql-workbench
    }
    else {
        Write-MissingToolWarning -Tool 'sql-workbench' -InstallHint 'Install with: scoop install sql-workbench'
    }
}

# DBeaver - launch DBeaver
<#
.SYNOPSIS
    Launches DBeaver Universal Database Tool.

.DESCRIPTION
    Opens DBeaver, a universal database tool that supports many database types.

.EXAMPLE
    Invoke-DBeaver
#>
function Invoke-DBeaver {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand dbeaver) {
        dbeaver
    }
    else {
        Write-MissingToolWarning -Tool 'dbeaver' -InstallHint 'Install with: scoop install dbeaver'
    }
}

# TablePlus - launch TablePlus
<#
.SYNOPSIS
    Launches TablePlus.

.DESCRIPTION
    Opens TablePlus, a modern database client with a clean interface.

.EXAMPLE
    Invoke-TablePlus
#>
function Invoke-TablePlus {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand tableplus) {
        tableplus
    }
    else {
        Write-MissingToolWarning -Tool 'tableplus' -InstallHint 'Install with: scoop install tableplus'
    }
}

# Hasura CLI - Hasura GraphQL engine CLI
<#
.SYNOPSIS
    Executes Hasura CLI commands.

.DESCRIPTION
    Wrapper function for Hasura CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to hasura.

.EXAMPLE
    Invoke-Hasura version

.EXAMPLE
    Invoke-Hasura migrate apply
#>
function Invoke-Hasura {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand hasura-cli) {
        hasura-cli @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'hasura-cli' -InstallHint 'Install with: scoop install hasura-cli'
    }
}

# Supabase CLI - Supabase CLI wrapper
<#
.SYNOPSIS
    Executes Supabase CLI commands.

.DESCRIPTION
    Wrapper function for Supabase CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to supabase.

.EXAMPLE
    Invoke-Supabase status

.EXAMPLE
    Invoke-Supabase start
#>
function Invoke-Supabase {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand supabase-beta) {
        supabase-beta @Arguments
    }
    elseif (Test-CachedCommand supabase) {
        supabase @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'supabase' -InstallHint 'Install with: scoop install supabase-beta'
    }
}

# ===============================================
# Connect-Database - Universal database connection
# ===============================================

<#
.SYNOPSIS
    Connects to a database using available client tools.

.DESCRIPTION
    Provides a universal interface for connecting to various database types.
    Automatically detects available database client tools and uses the appropriate one.

.PARAMETER DatabaseType
    Database type: PostgreSQL, MySQL, SQLite, MongoDB, SQLServer, Oracle.

.PARAMETER ConnectionString
    Database connection string or connection parameters.

.PARAMETER Host
    Database host name or IP address.

.PARAMETER Port
    Database port number.

.PARAMETER Database
    Database name.

.PARAMETER Credential
    PSCredential object containing username and password.

.PARAMETER UseGui
    Use GUI client if available (default: true).

.EXAMPLE
    $cred = Get-Credential
    Connect-Database -DatabaseType PostgreSQL -Host localhost -Database mydb -Credential $cred
    
    Connects to PostgreSQL database using GUI client.

.EXAMPLE
    Connect-Database -DatabaseType MySQL -ConnectionString "mysql://user:pass@localhost:3306/mydb"
    
    Connects using connection string.

.OUTPUTS
    System.Object. Connection information or process object.
#>
function Connect-Database {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB', 'SQLServer', 'Oracle')]
        [string]$DatabaseType,
        
        [string]$ConnectionString,
        
        [string]$Host,
        
        [int]$Port,
        
        [string]$Database,
        
        [PSCredential]$Credential,
        
        [switch]$UseGui = $true
    )
    
    try {
        switch ($DatabaseType) {
            'PostgreSQL' {
                if ($UseGui -and (Test-CachedCommand 'dbeaver')) {
                    if ($ConnectionString) {
                        Start-Process -FilePath 'dbeaver' -ArgumentList "--connection-string", $ConnectionString
                    }
                    else {
                        Write-Host "Opening DBeaver for PostgreSQL connection. Please configure connection manually." -ForegroundColor Yellow
                        Start-Process -FilePath 'dbeaver'
                    }
                }
                elseif (Test-CachedCommand 'psql') {
                    $args = @()
                    if ($Host) { $args += '-h', $Host }
                    if ($Port) { $args += '-p', $Port }
                    if ($Database) { $args += '-d', $Database }
                    if ($Credential) { $args += '-U', $Credential.UserName }
                    & psql $args
                }
                else {
                    Write-MissingToolWarning -Tool 'psql' -InstallHint 'Install PostgreSQL client or DBeaver'
                }
            }
            'MySQL' {
                if ($UseGui -and (Test-CachedCommand 'dbeaver')) {
                    if ($ConnectionString) {
                        Start-Process -FilePath 'dbeaver' -ArgumentList "--connection-string", $ConnectionString
                    }
                    else {
                        Write-Host "Opening DBeaver for MySQL connection. Please configure connection manually." -ForegroundColor Yellow
                        Start-Process -FilePath 'dbeaver'
                    }
                }
                elseif (Test-CachedCommand 'mysql') {
                    $args = @()
                    if ($Host) { $args += '-h', $Host }
                    if ($Port) { $args += '-P', $Port }
                    if ($Database) { $args += '-D', $Database }
                    if ($Credential) {
                        $args += '-u', $Credential.UserName
                        $securePassword = $Credential.GetNetworkCredential().Password
                        $args += "-p$securePassword"
                    }
                    & mysql $args
                }
                else {
                    Write-MissingToolWarning -Tool 'mysql' -InstallHint 'Install MySQL client or DBeaver'
                }
            }
            'SQLite' {
                if ($UseGui -and (Test-CachedCommand 'dbeaver')) {
                    if ($Database) {
                        Start-Process -FilePath 'dbeaver' -ArgumentList "--database", $Database
                    }
                    else {
                        Start-Process -FilePath 'dbeaver'
                    }
                }
                elseif (Test-CachedCommand 'sqlite3') {
                    if ($Database) {
                        & sqlite3 $Database
                    }
                    else {
                        Write-Error "Database path is required for SQLite"
                    }
                }
                else {
                    Write-MissingToolWarning -Tool 'sqlite3' -InstallHint 'Install SQLite or DBeaver'
                }
            }
            'MongoDB' {
                if ($UseGui -and (Test-CachedCommand 'mongodb-compass')) {
                    Invoke-MongoDbCompass
                }
                elseif (Test-CachedCommand 'mongosh') {
                    $args = @()
                    if ($ConnectionString) {
                        $args += $ConnectionString
                    }
                    elseif ($Host) {
                        $connection = "mongodb://"
                        if ($Credential) {
                            $securePassword = $Credential.GetNetworkCredential().Password
                            $connection += "$($Credential.UserName):${securePassword}@"
                        }
                        $connection += $Host
                        if ($Port) {
                            $connection += ":$Port"
                        }
                        if ($Database) {
                            $connection += "/$Database"
                        }
                        $args += $connection
                    }
                    & mongosh $args
                }
                else {
                    Write-MissingToolWarning -Tool 'mongosh' -InstallHint 'Install MongoDB Shell or MongoDB Compass'
                }
            }
            default {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        [System.ArgumentException]::new("Database type $DatabaseType is not yet fully supported"),
                        "UnsupportedDatabaseType",
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $DatabaseType
                    )
                    Write-StructuredError -ErrorRecord $errorRecord -OperationName "database.connect" -Context @{
                        database_type = $DatabaseType
                    }
                }
                else {
                    Write-Error "Database type $DatabaseType is not yet fully supported. Use GUI clients (DBeaver, TablePlus) for manual connection."
                }
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName "database.connect" -Context @{
                database_type = $DatabaseType
                host          = $Host
                port          = $Port
                database      = $Database
            }
        }
        else {
            Write-Error "Failed to connect to database: $_"
        }
    }
}

# ===============================================
# Query-Database - Execute queries
# ===============================================

<#
.SYNOPSIS
    Executes a database query.

.DESCRIPTION
    Executes a SQL or database query using available command-line tools.
    Supports PostgreSQL, MySQL, SQLite, and MongoDB.

.PARAMETER DatabaseType
    Database type: PostgreSQL, MySQL, SQLite, MongoDB.

.PARAMETER Query
    SQL query or database command to execute.

.PARAMETER Database
    Database name or connection string.

.PARAMETER OutputFormat
    Output format: table, json, csv. Defaults to table.

.EXAMPLE
    Query-Database -DatabaseType PostgreSQL -Database mydb -Query "SELECT * FROM users LIMIT 10"
    
    Executes a PostgreSQL query.

.EXAMPLE
    Query-Database -DatabaseType MongoDB -Database mydb -Query "db.users.find().limit(10)"
    
    Executes a MongoDB query.

.OUTPUTS
    System.Object. Query results.
#>
function Query-Database {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB')]
        [string]$DatabaseType,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [string]$Database,
        
        [ValidateSet('table', 'json', 'csv')]
        [string]$OutputFormat = 'table'
    )
    
    try {
        switch ($DatabaseType) {
            'PostgreSQL' {
                if (Test-CachedCommand 'psql') {
                    $args = @()
                    if ($Database) { $args += '-d', $Database }
                    $args += '-c', $Query
                    if ($OutputFormat -eq 'json') {
                        $args += '--json'
                    }
                    $output = & psql $args 2>&1
                    return $output
                }
                else {
                    Write-MissingToolWarning -Tool 'psql' -InstallHint 'Install PostgreSQL client'
                }
            }
            'MySQL' {
                if (Test-CachedCommand 'mysql') {
                    $args = @()
                    if ($Database) { $args += '-D', $Database }
                    $args += '-e', $Query
                    $output = & mysql $args 2>&1
                    return $output
                }
                else {
                    Write-MissingToolWarning -Tool 'mysql' -InstallHint 'Install MySQL client'
                }
            }
            'SQLite' {
                if (Test-CachedCommand 'sqlite3') {
                    if (-not $Database) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [System.ArgumentException]::new("Database path is required for SQLite"),
                                "MissingDatabasePath",
                                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                                $null
                            )
                            Write-StructuredError -ErrorRecord $errorRecord -OperationName "database.query" -Context @{
                                database_type = $DatabaseType
                            }
                        }
                        else {
                            Write-Error "Database path is required for SQLite"
                        }
                        return
                    }
                    $output = & sqlite3 $Database $Query 2>&1
                    return $output
                }
                else {
                    Write-MissingToolWarning -Tool 'sqlite3' -InstallHint 'Install SQLite'
                }
            }
            'MongoDB' {
                if (Test-CachedCommand 'mongosh') {
                    if (-not $Database) {
                        Write-Error "Database name is required for MongoDB"
                        return
                    }
                    $output = & mongosh $Database --eval $Query 2>&1
                    return $output
                }
                else {
                    Write-MissingToolWarning -Tool 'mongosh' -InstallHint 'Install MongoDB Shell'
                }
            }
        }
    }
    catch {
        Write-Error "Failed to execute query: $_"
    }
}

# ===============================================
# Export-Database - Export database
# ===============================================

<#
.SYNOPSIS
    Exports a database to a file.

.DESCRIPTION
    Exports database schema and/or data to a file using database-specific tools.
    Supports PostgreSQL, MySQL, SQLite, and MongoDB.

.PARAMETER DatabaseType
    Database type: PostgreSQL, MySQL, SQLite, MongoDB.

.PARAMETER Database
    Database name or connection string.

.PARAMETER OutputPath
    Path to output file.

.PARAMETER SchemaOnly
    Export only schema (no data).

.PARAMETER DataOnly
    Export only data (no schema).

.EXAMPLE
    Export-Database -DatabaseType PostgreSQL -Database mydb -OutputPath "backup.sql"
    
    Exports PostgreSQL database to SQL file.

.EXAMPLE
    Export-Database -DatabaseType MongoDB -Database mydb -OutputPath "backup.json" -DataOnly
    
    Exports MongoDB data to JSON file.

.OUTPUTS
    System.String. Path to exported file.
#>
function Export-Database {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB')]
        [string]$DatabaseType,
        
        [Parameter(Mandatory = $true)]
        [string]$Database,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [switch]$SchemaOnly,
        
        [switch]$DataOnly
    )
    
    try {
        switch ($DatabaseType) {
            'PostgreSQL' {
                if (Test-CachedCommand 'pg_dump') {
                    $args = @('-F', 'c', '-f', $OutputPath)
                    if ($SchemaOnly) { $args += '--schema-only' }
                    if ($DataOnly) { $args += '--data-only' }
                    $args += $Database
                    & pg_dump $args
                    if ($LASTEXITCODE -eq 0) {
                        return $OutputPath
                    }
                }
                else {
                    Write-MissingToolWarning -Tool 'pg_dump' -InstallHint 'Install PostgreSQL client tools'
                }
            }
            'MySQL' {
                if (Test-CachedCommand 'mysqldump') {
                    $args = @()
                    if ($SchemaOnly) { $args += '--no-data' }
                    if ($DataOnly) { $args += '--no-create-info' }
                    $args += $Database
                    & mysqldump $args | Out-File -FilePath $OutputPath -Encoding utf8
                    if ($LASTEXITCODE -eq 0) {
                        return $OutputPath
                    }
                }
                else {
                    Write-MissingToolWarning -Tool 'mysqldump' -InstallHint 'Install MySQL client tools'
                }
            }
            'SQLite' {
                if (Test-CachedCommand 'sqlite3') {
                    # SQLite export
                    $query = ".output $OutputPath"
                    if ($SchemaOnly) {
                        $query += "`n.schema"
                    }
                    elseif ($DataOnly) {
                        $query += "`n.mode insert"
                        $query += "`nSELECT * FROM sqlite_master WHERE type='table';"
                    }
                    else {
                        $query += "`n.dump"
                    }
                    & sqlite3 $Database $query
                    if ($LASTEXITCODE -eq 0) {
                        return $OutputPath
                    }
                }
                else {
                    Write-MissingToolWarning -Tool 'sqlite3' -InstallHint 'Install SQLite'
                }
            }
            'MongoDB' {
                if (Test-CachedCommand 'mongoexport') {
                    $args = @('-d', $Database, '-o', $OutputPath)
                    if ($SchemaOnly) {
                        Write-Warning "MongoDB does not support schema-only export. Exporting all collections."
                    }
                    & mongoexport $args
                    if ($LASTEXITCODE -eq 0) {
                        return $OutputPath
                    }
                }
                else {
                    Write-MissingToolWarning -Tool 'mongoexport' -InstallHint 'Install MongoDB Database Tools'
                }
            }
        }
    }
    catch {
        Write-Error "Failed to export database: $_"
    }
}

# ===============================================
# Import-Database - Import database
# ===============================================

<#
.SYNOPSIS
    Imports a database from a file.

.DESCRIPTION
    Imports database schema and/or data from a file using database-specific tools.
    Supports PostgreSQL, MySQL, SQLite, and MongoDB.

.PARAMETER DatabaseType
    Database type: PostgreSQL, MySQL, SQLite, MongoDB.

.PARAMETER Database
    Target database name.

.PARAMETER InputPath
    Path to input file.

.EXAMPLE
    Import-Database -DatabaseType PostgreSQL -Database mydb -InputPath "backup.sql"
    
    Imports PostgreSQL database from SQL file.

.EXAMPLE
    Import-Database -DatabaseType MongoDB -Database mydb -InputPath "backup.json"
    
    Imports MongoDB data from JSON file.

.OUTPUTS
    System.Boolean. True if import successful.
#>
function Import-Database {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB')]
        [string]$DatabaseType,
        
        [Parameter(Mandatory = $true)]
        [string]$Database,
        
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )
    
    if (-not (Test-Path -LiteralPath $InputPath)) {
        Write-Error "Input file not found: $InputPath"
        return $false
    }
    
    try {
        switch ($DatabaseType) {
            'PostgreSQL' {
                if (Test-CachedCommand 'psql') {
                    Get-Content -LiteralPath $InputPath | & psql -d $Database
                    return $LASTEXITCODE -eq 0
                }
                else {
                    Write-MissingToolWarning -Tool 'psql' -InstallHint 'Install PostgreSQL client tools'
                    return $false
                }
            }
            'MySQL' {
                if (Test-CachedCommand 'mysql') {
                    Get-Content -LiteralPath $InputPath | & mysql -D $Database
                    return $LASTEXITCODE -eq 0
                }
                else {
                    Write-MissingToolWarning -Tool 'mysql' -InstallHint 'Install MySQL client tools'
                    return $false
                }
            }
            'SQLite' {
                if (Test-CachedCommand 'sqlite3') {
                    Get-Content -LiteralPath $InputPath | & sqlite3 $Database
                    return $LASTEXITCODE -eq 0
                }
                else {
                    Write-MissingToolWarning -Tool 'sqlite3' -InstallHint 'Install SQLite'
                    return $false
                }
            }
            'MongoDB' {
                if (Test-CachedCommand 'mongoimport') {
                    # Determine collection name from file or use default
                    $collection = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
                    & mongoimport -d $Database -c $collection --file $InputPath
                    return $LASTEXITCODE -eq 0
                }
                else {
                    Write-MissingToolWarning -Tool 'mongoimport' -InstallHint 'Install MongoDB Database Tools'
                    return $false
                }
            }
        }
    }
    catch {
        Write-Error "Failed to import database: $_"
        return $false
    }
}

# ===============================================
# Backup-Database - Backup database
# ===============================================

<#
.SYNOPSIS
    Creates a backup of a database.

.DESCRIPTION
    Creates a backup of a database using database-specific backup tools.
    Supports PostgreSQL, MySQL, SQLite, and MongoDB.

.PARAMETER DatabaseType
    Database type: PostgreSQL, MySQL, SQLite, MongoDB.

.PARAMETER Database
    Database name or connection string.

.PARAMETER BackupPath
    Path to backup file. Defaults to database name with timestamp.

.PARAMETER Compress
    Compress the backup file.

.EXAMPLE
    Backup-Database -DatabaseType PostgreSQL -Database mydb
    
    Creates a PostgreSQL backup.

.EXAMPLE
    Backup-Database -DatabaseType MySQL -Database mydb -BackupPath "backup.sql" -Compress
    
    Creates a compressed MySQL backup.

.OUTPUTS
    System.String. Path to backup file.
#>
function Backup-Database {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB')]
        [string]$DatabaseType,
        
        [Parameter(Mandatory = $true)]
        [string]$Database,
        
        [string]$BackupPath,
        
        [switch]$Compress
    )
    
    if (-not $BackupPath) {
        $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
        $BackupPath = "$Database-$timestamp"
        if ($DatabaseType -eq 'PostgreSQL') {
            $BackupPath += '.dump'
        }
        elseif ($DatabaseType -eq 'MongoDB') {
            $BackupPath += '.archive'
        }
        else {
            $BackupPath += '.sql'
        }
    }
    
    # Use Export-Database for backup
    $exportParams = @{
        DatabaseType = $DatabaseType
        Database     = $Database
        OutputPath   = $BackupPath
    }
    
    $result = Export-Database @exportParams
    
    if ($result -and $Compress) {
        $compressedPath = "$BackupPath.gz"
        Compress-Archive -Path $BackupPath -DestinationPath $compressedPath -Force
        Remove-Item -LiteralPath $BackupPath -Force
        return $compressedPath
    }
    
    return $result
}

# ===============================================
# Restore-Database - Restore database
# ===============================================

<#
.SYNOPSIS
    Restores a database from a backup.

.DESCRIPTION
    Restores a database from a backup file using database-specific restore tools.
    Supports PostgreSQL, MySQL, SQLite, and MongoDB.

.PARAMETER DatabaseType
    Database type: PostgreSQL, MySQL, SQLite, MongoDB.

.PARAMETER Database
    Target database name.

.PARAMETER BackupPath
    Path to backup file.

.EXAMPLE
    Restore-Database -DatabaseType PostgreSQL -Database mydb -BackupPath "backup.dump"
    
    Restores PostgreSQL database from backup.

.EXAMPLE
    Restore-Database -DatabaseType MySQL -Database mydb -BackupPath "backup.sql.gz"
    
    Restores MySQL database from compressed backup.

.OUTPUTS
    System.Boolean. True if restore successful.
#>
function Restore-Database {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB')]
        [string]$DatabaseType,
        
        [Parameter(Mandatory = $true)]
        [string]$Database,
        
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )
    
    if (-not (Test-Path -LiteralPath $BackupPath)) {
        Write-Error "Backup file not found: $BackupPath"
        return $false
    }
    
    if (-not $PSCmdlet.ShouldProcess($Database, "Restore database from $BackupPath")) {
        return $false
    }
    
    # Handle compressed backups
    $actualPath = $BackupPath
    if ($BackupPath.EndsWith('.gz')) {
        $extractedPath = $BackupPath -replace '\.gz$', ''
        Expand-Archive -Path $BackupPath -DestinationPath (Split-Path $extractedPath) -Force
        $actualPath = $extractedPath
    }
    
    # Use Import-Database for restore
    $importParams = @{
        DatabaseType = $DatabaseType
        Database     = $Database
        InputPath    = $actualPath
    }
    
    return Import-Database @importParams
}

# ===============================================
# Get-DatabaseSchema - Get schema information
# ===============================================

<#
.SYNOPSIS
    Gets database schema information.

.DESCRIPTION
    Retrieves schema information (tables, columns, indexes, etc.) from a database.
    Supports PostgreSQL, MySQL, SQLite, and MongoDB.

.PARAMETER DatabaseType
    Database type: PostgreSQL, MySQL, SQLite, MongoDB.

.PARAMETER Database
    Database name or connection string.

.PARAMETER TableName
    Optional specific table name to get schema for.

.PARAMETER OutputFormat
    Output format: table, json. Defaults to table.

.EXAMPLE
    Get-DatabaseSchema -DatabaseType PostgreSQL -Database mydb
    
    Gets schema for all tables in PostgreSQL database.

.EXAMPLE
    Get-DatabaseSchema -DatabaseType MySQL -Database mydb -TableName users -OutputFormat json
    
    Gets schema for specific table in JSON format.

.OUTPUTS
    System.Object. Schema information.
#>
function Get-DatabaseSchema {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB')]
        [string]$DatabaseType,
        
        [Parameter(Mandatory = $true)]
        [string]$Database,
        
        [string]$TableName,
        
        [ValidateSet('table', 'json')]
        [string]$OutputFormat = 'table'
    )
    
    try {
        switch ($DatabaseType) {
            'PostgreSQL' {
                if (Test-CachedCommand 'psql') {
                    $query = @"
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
"@
                    if ($TableName) {
                        $query += " AND table_name = '$TableName'"
                    }
                    $query += " ORDER BY table_name, ordinal_position;"
                    
                    $result = Query-Database -DatabaseType PostgreSQL -Database $Database -Query $query
                    return $result
                }
                else {
                    Write-MissingToolWarning -Tool 'psql' -InstallHint 'Install PostgreSQL client'
                }
            }
            'MySQL' {
                if (Test-CachedCommand 'mysql') {
                    $query = "SHOW TABLES;"
                    if ($TableName) {
                        $query = "DESCRIBE $TableName;"
                    }
                    $result = Query-Database -DatabaseType MySQL -Database $Database -Query $query
                    return $result
                }
                else {
                    Write-MissingToolWarning -Tool 'mysql' -InstallHint 'Install MySQL client'
                }
            }
            'SQLite' {
                if (Test-CachedCommand 'sqlite3') {
                    $query = ".schema"
                    if ($TableName) {
                        $query = ".schema $TableName"
                    }
                    $result = Query-Database -DatabaseType SQLite -Database $Database -Query $query
                    return $result
                }
                else {
                    Write-MissingToolWarning -Tool 'sqlite3' -InstallHint 'Install SQLite'
                }
            }
            'MongoDB' {
                if (Test-CachedCommand 'mongosh') {
                    $query = "db.getCollectionNames()"
                    if ($TableName) {
                        $query = "db.$TableName.findOne()"
                    }
                    $result = Query-Database -DatabaseType MongoDB -Database $Database -Query $query
                    return $result
                }
                else {
                    Write-MissingToolWarning -Tool 'mongosh' -InstallHint 'Install MongoDB Shell'
                }
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName "database.schema.get" -Context @{
                database_type = $DatabaseType
                database      = $Database
            }
        }
        else {
            Write-Error "Failed to get database schema: $_"
        }
    }
}

# Register new functions
if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Connect-Database' -Body ${function:Connect-Database}
    Set-AgentModeFunction -Name 'Query-Database' -Body ${function:Query-Database}
    Set-AgentModeFunction -Name 'Export-Database' -Body ${function:Export-Database}
    Set-AgentModeFunction -Name 'Import-Database' -Body ${function:Import-Database}
    Set-AgentModeFunction -Name 'Backup-Database' -Body ${function:Backup-Database}
    Set-AgentModeFunction -Name 'Restore-Database' -Body ${function:Restore-Database}
    Set-AgentModeFunction -Name 'Get-DatabaseSchema' -Body ${function:Get-DatabaseSchema}
}
else {
    # Fallback: direct function registration
    Set-Item -Path Function:Connect-Database -Value ${function:Connect-Database} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Query-Database -Value ${function:Query-Database} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Export-Database -Value ${function:Export-Database} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Import-Database -Value ${function:Import-Database} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Backup-Database -Value ${function:Backup-Database} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Restore-Database -Value ${function:Restore-Database} -Force -ErrorAction SilentlyContinue
    Set-Item -Path Function:Get-DatabaseSchema -Value ${function:Get-DatabaseSchema} -Force -ErrorAction SilentlyContinue
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'mongodb-compass' -Target 'Invoke-MongoDbCompass'
    Set-AgentModeAlias -Name 'sql-workbench' -Target 'Invoke-SqlWorkbench'
    Set-AgentModeAlias -Name 'dbeaver' -Target 'Invoke-DBeaver'
    Set-AgentModeAlias -Name 'tableplus' -Target 'Invoke-TablePlus'
    Set-AgentModeAlias -Name 'hasura' -Target 'Invoke-Hasura'
    Set-AgentModeAlias -Name 'supabase' -Target 'Invoke-Supabase'
    Set-AgentModeAlias -Name 'db-connect' -Target 'Connect-Database'
    Set-AgentModeAlias -Name 'db-query' -Target 'Query-Database'
    Set-AgentModeAlias -Name 'db-export' -Target 'Export-Database'
    Set-AgentModeAlias -Name 'db-import' -Target 'Import-Database'
    Set-AgentModeAlias -Name 'db-backup' -Target 'Backup-Database'
    Set-AgentModeAlias -Name 'db-restore' -Target 'Restore-Database'
    Set-AgentModeAlias -Name 'db-schema' -Target 'Get-DatabaseSchema'
}
else {
    Set-Alias -Name 'mongodb-compass' -Value 'Invoke-MongoDbCompass' -ErrorAction SilentlyContinue
    Set-Alias -Name 'sql-workbench' -Value 'Invoke-SqlWorkbench' -ErrorAction SilentlyContinue
    Set-Alias -Name 'dbeaver' -Value 'Invoke-DBeaver' -ErrorAction SilentlyContinue
    Set-Alias -Name 'tableplus' -Value 'Invoke-TablePlus' -ErrorAction SilentlyContinue
    Set-Alias -Name 'hasura' -Value 'Invoke-Hasura' -ErrorAction SilentlyContinue
    Set-Alias -Name 'supabase' -Value 'Invoke-Supabase' -ErrorAction SilentlyContinue
    Set-Alias -Name 'db-connect' -Value 'Connect-Database' -ErrorAction SilentlyContinue
    Set-Alias -Name 'db-query' -Value 'Query-Database' -ErrorAction SilentlyContinue
    Set-Alias -Name 'db-export' -Value 'Export-Database' -ErrorAction SilentlyContinue
    Set-Alias -Name 'db-import' -Value 'Import-Database' -ErrorAction SilentlyContinue
    Set-Alias -Name 'db-backup' -Value 'Backup-Database' -ErrorAction SilentlyContinue
    Set-Alias -Name 'db-restore' -Value 'Restore-Database' -ErrorAction SilentlyContinue
    Set-Alias -Name 'db-schema' -Value 'Get-DatabaseSchema' -ErrorAction SilentlyContinue
}

