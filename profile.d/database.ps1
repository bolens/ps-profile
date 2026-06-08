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
    Provides PowerShell functions and aliases for universal database client operations.
    Supports PostgreSQL, MySQL, SQLite, MongoDB, SQL Server, and Oracle.
    GUI client launchers (MongoDB Compass, DBeaver, TablePlus, etc.) are in database-clients.ps1.
    Functions check for tool availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Database
    Author: PowerShell Profile
#>
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


.PARAMETER ServerHost
    Database host name or IP address.


.PARAMETER Port
    Database port number.


.PARAMETER Database
    Database name.


.PARAMETER Credential
    PSCredential object containing username and password.


.PARAMETER UseGui
    Use GUI client if available (default: true).


.OUTPUTS
    System.Object. Connection information or process object.

.EXAMPLE
    $cred = Get-Credential
    Connect-Database -DatabaseType PostgreSQL -ServerHost localhost -Database mydb -Credential $cred
    
    Connects to PostgreSQL database using GUI client.


.EXAMPLE
    Connect-Database -DatabaseType MySQL -ConnectionString "mysql://user:pass@localhost:3306/mydb"
    
    Connects using connection string.
#>
function Connect-Database {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PostgreSQL', 'MySQL', 'SQLite', 'MongoDB', 'SQLServer', 'Oracle')]
        [string]$DatabaseType,
        
        [string]$ConnectionString,
        
        [string]$ServerHost,
        
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
                    if ($ServerHost) { $args += '-h', $ServerHost }
                    if ($Port) { $args += '-p', $Port }
                    if ($Database) { $args += '-d', $Database }
                    if ($Credential) { $args += '-U', $Credential.UserName }
                    & psql $args
                }
                else {
                    Invoke-MissingToolWarning -ToolName 'psql'
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
                    if ($ServerHost) { $args += '-h', $ServerHost }
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
                    Invoke-MissingToolWarning -ToolName 'mysql'
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
                    Invoke-MissingToolWarning -ToolName 'sqlite3'
                }
            }
            'MongoDB' {
                if ($UseGui -and (Test-CachedCommand 'mongodb-compass')) {
                    Start-MongoDbCompass
                }
                elseif (Test-CachedCommand 'mongosh') {
                    $args = @()
                    if ($ConnectionString) {
                        $args += $ConnectionString
                    }
                    elseif ($ServerHost) {
                        $connection = "mongodb://"
                        if ($Credential) {
                            $securePassword = $Credential.GetNetworkCredential().Password
                            $connection += "$($Credential.UserName):${securePassword}@"
                        }
                        $connection += $ServerHost
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
                    Invoke-MissingToolWarning -ToolName 'mongosh'
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
                host          = $ServerHost
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


.OUTPUTS
    System.Object. Query results.

.EXAMPLE
    Query-Database -DatabaseType PostgreSQL -Database mydb -Query "SELECT * FROM users LIMIT 10"
    
    Executes a PostgreSQL query.


.EXAMPLE
    Query-Database -DatabaseType MongoDB -Database mydb -Query "db.users.find().limit(10)"
    
    Executes a MongoDB query.
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
                    Invoke-MissingToolWarning -ToolName 'psql'
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
                    Invoke-MissingToolWarning -ToolName 'mysql'
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
                    Invoke-MissingToolWarning -ToolName 'sqlite3'
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
                    Invoke-MissingToolWarning -ToolName 'mongosh'
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


.OUTPUTS
    System.String. Path to exported file.

.EXAMPLE
    Export-Database -DatabaseType PostgreSQL -Database mydb -OutputPath "backup.sql"
    
    Exports PostgreSQL database to SQL file.


.EXAMPLE
    Export-Database -DatabaseType MongoDB -Database mydb -OutputPath "backup.json" -DataOnly
    
    Exports MongoDB data to JSON file.
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
                    Invoke-MissingToolWarning -ToolName 'pg_dump'
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
                    Invoke-MissingToolWarning -ToolName 'mysqldump'
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
                    Invoke-MissingToolWarning -ToolName 'sqlite3'
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
                    Invoke-MissingToolWarning -ToolName 'mongoexport'
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


.OUTPUTS
    System.Boolean. True if import successful.

.EXAMPLE
    Import-Database -DatabaseType PostgreSQL -Database mydb -InputPath "backup.sql"
    
    Imports PostgreSQL database from SQL file.


.EXAMPLE
    Import-Database -DatabaseType MongoDB -Database mydb -InputPath "backup.json"
    
    Imports MongoDB data from JSON file.
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
                    Invoke-MissingToolWarning -ToolName 'psql'
                    return $false
                }
            }
            'MySQL' {
                if (Test-CachedCommand 'mysql') {
                    Get-Content -LiteralPath $InputPath | & mysql -D $Database
                    return $LASTEXITCODE -eq 0
                }
                else {
                    Invoke-MissingToolWarning -ToolName 'mysql'
                    return $false
                }
            }
            'SQLite' {
                if (Test-CachedCommand 'sqlite3') {
                    Get-Content -LiteralPath $InputPath | & sqlite3 $Database
                    return $LASTEXITCODE -eq 0
                }
                else {
                    Invoke-MissingToolWarning -ToolName 'sqlite3'
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
                    Invoke-MissingToolWarning -ToolName 'mongoimport'
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


.OUTPUTS
    System.String. Path to backup file.

.EXAMPLE
    Backup-Database -DatabaseType PostgreSQL -Database mydb
    
    Creates a PostgreSQL backup.


.EXAMPLE
    Backup-Database -DatabaseType MySQL -Database mydb -BackupPath "backup.sql" -Compress
    
    Creates a compressed MySQL backup.
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


.OUTPUTS
    System.Boolean. True if restore successful.

.EXAMPLE
    Restore-Database -DatabaseType PostgreSQL -Database mydb -BackupPath "backup.dump"
    
    Restores PostgreSQL database from backup.


.EXAMPLE
    Restore-Database -DatabaseType MySQL -Database mydb -BackupPath "backup.sql.gz"
    
    Restores MySQL database from compressed backup.
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


.OUTPUTS
    System.Object. Schema information.

.EXAMPLE
    Get-DatabaseSchema -DatabaseType PostgreSQL -Database mydb
    
    Gets schema for all tables in PostgreSQL database.


.EXAMPLE
    Get-DatabaseSchema -DatabaseType MySQL -Database mydb -TableName users -OutputFormat json
    
    Gets schema for specific table in JSON format.
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
                    Invoke-MissingToolWarning -ToolName 'psql'
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
                    Invoke-MissingToolWarning -ToolName 'mysql'
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
                    Invoke-MissingToolWarning -ToolName 'sqlite3'
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
                    Invoke-MissingToolWarning -ToolName 'mongosh'
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
Set-AgentModeFunction -Name 'Connect-Database' -Body ${function:Connect-Database}
Set-AgentModeFunction -Name 'Query-Database' -Body ${function:Query-Database}
Set-AgentModeFunction -Name 'Export-Database' -Body ${function:Export-Database}
Set-AgentModeFunction -Name 'Import-Database' -Body ${function:Import-Database}
Set-AgentModeFunction -Name 'Backup-Database' -Body ${function:Backup-Database}
Set-AgentModeFunction -Name 'Restore-Database' -Body ${function:Restore-Database}
Set-AgentModeFunction -Name 'Get-DatabaseSchema' -Body ${function:Get-DatabaseSchema}

# Create aliases for short forms
Set-AgentModeAlias -Name 'db-connect' -Target 'Connect-Database'
Set-AgentModeAlias -Name 'db-query' -Target 'Query-Database'
Set-AgentModeAlias -Name 'db-export' -Target 'Export-Database'
Set-AgentModeAlias -Name 'db-import' -Target 'Import-Database'
Set-AgentModeAlias -Name 'db-backup' -Target 'Backup-Database'
Set-AgentModeAlias -Name 'db-restore' -Target 'Restore-Database'
Set-AgentModeAlias -Name 'db-schema' -Target 'Get-DatabaseSchema'

