# ===============================================
# SQLite database format conversion utilities
# SQLite ↔ JSON, CSV, SQL
# ===============================================

<#
.SYNOPSIS
    Initializes SQLite database format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for SQLite database format.
    SQLite is a lightweight, file-based SQL database engine.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires SQLite command-line tool (sqlite3) or .NET System.Data.SQLite to be installed.
#>
function Initialize-FileConversion-DatabaseSqlite {
    # SQLite to JSON
    Set-Item -Path Function:Global:_ConvertFrom-SqliteToJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$TableName)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(db|sqlite|sqlite3)$', '.json' }
            
            # Try sqlite3 command first
            if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
                $tempJson = Join-Path $env:TEMP "sqlite-to-json-$(Get-Random).json"
                try {
                    if ($TableName) {
                        # Export specific table
                        $query = "SELECT * FROM [$TableName];"
                        $result = & sqlite3 -json $InputPath $query 2>&1
                        $exitCode = $LASTEXITCODE
                        if ($exitCode -ne 0) {
                            $errorText = if ($result) { ($result | Out-String).Trim() } else { "No additional error output." }
                            throw "sqlite3 failed with exit code $exitCode when exporting table '$TableName' from '$InputPath'. Error: $errorText"
                        }
                        # sqlite3 -json outputs array of objects
                        $result | Set-Content -LiteralPath $tempJson -Encoding UTF8
                    }
                    else {
                        # Export all tables
                        $tables = & sqlite3 $InputPath ".tables" 2>&1
                        $exitCode = $LASTEXITCODE
                        if ($exitCode -ne 0) {
                            $errorText = if ($tables) { ($tables | Out-String).Trim() } else { "No additional error output." }
                            throw "sqlite3 failed with exit code $exitCode when listing tables in '$InputPath'. Error: $errorText"
                        }
                        $tableList = ($tables -split '\s+') | Where-Object { $_ -and -not $_.StartsWith('.') }
                        $allData = @{}
                        foreach ($table in $tableList) {
                            $tableData = & sqlite3 -json $InputPath "SELECT * FROM [$table];" 2>&1
                            $tableExit = $LASTEXITCODE
                            if ($tableExit -eq 0) {
                                $allData[$table] = ($tableData | ConvertFrom-Json)
                            }
                            else {
                                $errorText = if ($tableData) { ($tableData | Out-String).Trim() } else { "No additional error output." }
                                Write-Warning "sqlite3 failed with exit code $tableExit when exporting table '$table' from '$InputPath'. Error: $errorText"
                            }
                        }
                        $allData | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tempJson -Encoding UTF8
                    }
                    Copy-Item -LiteralPath $tempJson -Destination $OutputPath -Force
                }
                finally {
                    Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
                }
                return
            }
            
            # Fallback to .NET System.Data.SQLite
            try {
                Add-Type -Path "System.Data.SQLite.dll" -ErrorAction Stop
            }
            catch {
                # Try loading from common locations
                $sqliteDll = @(
                    "$env:ProgramFiles\SQLite\System.Data.SQLite.dll",
                    "$env:ProgramFiles(x86)\SQLite\System.Data.SQLite.dll",
                    (Get-ChildItem -Path "$env:ProgramFiles" -Filter "System.Data.SQLite.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
                ) | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
                
                if ($sqliteDll) {
                    Add-Type -Path $sqliteDll
                }
                else {
                    throw "SQLite is not available. Install sqlite3 command-line tool or System.Data.SQLite.dll to use SQLite conversions."
                }
            }
            
            $connectionString = "Data Source=$InputPath;Version=3;"
            $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $connection.Open()
            
            try {
                if ($TableName) {
                    $command = $connection.CreateCommand()
                    $command.CommandText = "SELECT * FROM [$TableName];"
                    $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
                    $dataset = New-Object System.Data.DataSet
                    $adapter.Fill($dataset) | Out-Null
                    $table = $dataset.Tables[0]
                    $result = @()
                    foreach ($row in $table.Rows) {
                        $obj = @{}
                        foreach ($column in $table.Columns) {
                            $obj[$column.ColumnName] = $row[$column]
                        }
                        $result += $obj
                    }
                    $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                }
                else {
                    # Get all tables
                    $command = $connection.CreateCommand()
                    $command.CommandText = "SELECT name FROM sqlite_master WHERE type='table';"
                    $reader = $command.ExecuteReader()
                    $tables = @()
                    while ($reader.Read()) {
                        $tables += $reader.GetString(0)
                    }
                    $reader.Close()
                    
                    $allData = @{}
                    foreach ($tableName in $tables) {
                        $command.CommandText = "SELECT * FROM [$tableName];"
                        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
                        $dataset = New-Object System.Data.DataSet
                        $adapter.Fill($dataset) | Out-Null
                        $table = $dataset.Tables[0]
                        $result = @()
                        foreach ($row in $table.Rows) {
                            $obj = @{}
                            foreach ($column in $table.Columns) {
                                $obj[$column.ColumnName] = $row[$column]
                            }
                            $result += $obj
                        }
                        $allData[$tableName] = $result
                    }
                    $allData | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                }
            }
            finally {
                $connection.Close()
            }
        }
        catch {
            Write-Error "Failed to convert SQLite database '$InputPath' to JSON at '$OutputPath': $($_.Exception.Message)"
            throw
        }
    } -Force

    # JSON to SQLite
    Set-Item -Path Function:Global:_ConvertTo-SqliteFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$TableName = 'data')
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.db' }
            
            $jsonData = Get-Content -LiteralPath $InputPath -Raw -Encoding UTF8 | ConvertFrom-Json
            
            # Try sqlite3 command first
            if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
                # Remove existing database if it exists
                if ($OutputPath -and -not [string]::IsNullOrWhiteSpace($OutputPath) -and (Test-Path -LiteralPath $OutputPath)) {
                    Remove-Item -LiteralPath $OutputPath -Force
                }
                
                if ($jsonData -is [System.Collections.Hashtable] -or $jsonData -is [PSCustomObject]) {
                    # Multiple tables
                    $jsonObj = if ($jsonData -is [PSCustomObject]) { $jsonData | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $jsonData }
                    foreach ($table in $jsonObj.Keys) {
                        $tableData = $jsonObj[$table]
                        if ($tableData -is [Array]) {
                            # Create table and insert data
                            if ($tableData.Count -gt 0) {
                                $firstRow = $tableData[0]
                                $columns = if ($firstRow -is [PSCustomObject]) { 
                                    ($firstRow | Get-Member -MemberType NoteProperty).Name 
                                }
                                else { 
                                    $firstRow.Keys 
                                }
                                $createTable = "CREATE TABLE IF NOT EXISTS [$table] (" + 
                                ($columns | ForEach-Object { "[$_] TEXT" }) -join ', ' + ");"
                                & sqlite3 $OutputPath $createTable 2>&1 | Out-Null
                                
                                foreach ($row in $tableData) {
                                    $rowObj = if ($row -is [PSCustomObject]) { $row | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $row }
                                    $values = ($columns | ForEach-Object { 
                                            $val = $rowObj[$_]
                                            if ($null -eq $val) { "NULL" } else { "'$($val -replace "'", "''")'" }
                                        }) -join ', '
                                    $insert = "INSERT INTO [$table] ([$($columns -join '], [')]) VALUES ($values);"
                                    & sqlite3 $OutputPath $insert 2>&1 | Out-Null
                                }
                            }
                        }
                    }
                }
                else {
                    # Single table
                    $tableData = if ($jsonData -is [Array]) { $jsonData } else { @($jsonData) }
                    if ($tableData.Count -gt 0) {
                        $firstRow = $tableData[0]
                        $columns = if ($firstRow -is [PSCustomObject]) { 
                            ($firstRow | Get-Member -MemberType NoteProperty).Name 
                        }
                        else { 
                            $firstRow.Keys 
                        }
                        $createTable = "CREATE TABLE IF NOT EXISTS [$TableName] (" + 
                        ($columns | ForEach-Object { "[$_] TEXT" }) -join ', ' + ");"
                        & sqlite3 $OutputPath $createTable 2>&1 | Out-Null
                        
                        foreach ($row in $tableData) {
                            $rowObj = if ($row -is [PSCustomObject]) { $row | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $row }
                            $values = ($columns | ForEach-Object { 
                                    $val = $rowObj[$_]
                                    if ($null -eq $val) { "NULL" } else { "'$($val -replace "'", "''")'" }
                                }) -join ', '
                            $insert = "INSERT INTO [$TableName] ([$($columns -join '], [')]) VALUES ($values);"
                            & sqlite3 $OutputPath $insert 2>&1 | Out-Null
                        }
                    }
                }
                return
            }
            
            throw "SQLite is not available. Install sqlite3 command-line tool to use SQLite conversions."
        }
        catch {
            Write-Error "Failed to convert JSON to SQLite: $_"
            throw
        }
    } -Force

    # SQLite to CSV
    Set-Item -Path Function:Global:_ConvertFrom-SqliteToCsv -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$TableName)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(db|sqlite|sqlite3)$', '.csv' }
            
            if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
                if ($TableName) {
                    & sqlite3 -header -csv $InputPath "SELECT * FROM [$TableName];" | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                }
                else {
                    # Export first table or all tables
                    $tables = & sqlite3 $InputPath ".tables" 2>&1
                    $tableList = ($tables -split '\s+') | Where-Object { $_ -and -not $_.StartsWith('.') } | Select-Object -First 1
                    if ($tableList) {
                        & sqlite3 -header -csv $InputPath "SELECT * FROM [$tableList];" | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                    }
                    else {
                        throw "No tables found in SQLite database"
                    }
                }
                if ($LASTEXITCODE -ne 0) {
                    throw "sqlite3 failed with exit code $LASTEXITCODE"
                }
                return
            }
            
            throw "SQLite is not available. Install sqlite3 command-line tool to use SQLite conversions."
        }
        catch {
            Write-Error "Failed to convert SQLite to CSV: $_"
            throw
        }
    } -Force

    # SQLite to SQL Dump
    Set-Item -Path Function:Global:_ConvertFrom-SqliteToSql -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(db|sqlite|sqlite3)$', '.sql' }
            
            if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
                & sqlite3 $InputPath ".dump" | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                if ($LASTEXITCODE -ne 0) {
                    throw "sqlite3 failed with exit code $LASTEXITCODE"
                }
                return
            }
            
            throw "SQLite is not available. Install sqlite3 command-line tool to use SQLite conversions."
        }
        catch {
            Write-Error "Failed to convert SQLite to SQL: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert SQLite to JSON
<#
.SYNOPSIS
    Converts SQLite database to JSON format.
.DESCRIPTION
    Converts a SQLite database file to JSON format.
    Exports table data from SQLite database.
    Requires SQLite command-line tool (sqlite3) or .NET System.Data.SQLite to be installed.
.PARAMETER InputPath
    The path to the SQLite database file (.db, .sqlite, or .sqlite3 extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.PARAMETER TableName
    Optional. Name of the table to export. If not specified, exports all tables.
#>
function ConvertFrom-SqliteToJson {
    param([string]$InputPath, [string]$OutputPath, [string]$TableName)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SqliteToJson @PSBoundParameters
}
Set-Alias -Name sqlite-to-json -Value ConvertFrom-SqliteToJson -ErrorAction SilentlyContinue
Set-Alias -Name db-to-json -Value ConvertFrom-SqliteToJson -ErrorAction SilentlyContinue

# Convert JSON to SQLite
<#
.SYNOPSIS
    Converts JSON file to SQLite database format.
.DESCRIPTION
    Converts a JSON file to SQLite database format.
    Creates a SQLite database with tables based on JSON structure.
    Requires SQLite command-line tool (sqlite3) to be installed.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output SQLite database file. If not specified, uses input path with .db extension.
.PARAMETER TableName
    Optional. Name of the table to create. Defaults to 'data'. Ignored if JSON contains multiple tables.
#>
function ConvertTo-SqliteFromJson {
    param([string]$InputPath, [string]$OutputPath, [string]$TableName = 'data')
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SqliteFromJson @PSBoundParameters
}
Set-Alias -Name json-to-sqlite -Value ConvertTo-SqliteFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-db -Value ConvertTo-SqliteFromJson -ErrorAction SilentlyContinue

# Convert SQLite to CSV
<#
.SYNOPSIS
    Converts SQLite database to CSV format.
.DESCRIPTION
    Converts a SQLite database file to CSV format.
    Exports table data from SQLite database.
    Requires SQLite command-line tool (sqlite3) to be installed.
.PARAMETER InputPath
    The path to the SQLite database file (.db, .sqlite, or .sqlite3 extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
.PARAMETER TableName
    Optional. Name of the table to export. If not specified, exports the first table.
#>
function ConvertFrom-SqliteToCsv {
    param([string]$InputPath, [string]$OutputPath, [string]$TableName)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SqliteToCsv @PSBoundParameters
}
Set-Alias -Name sqlite-to-csv -Value ConvertFrom-SqliteToCsv -ErrorAction SilentlyContinue
Set-Alias -Name db-to-csv -Value ConvertFrom-SqliteToCsv -ErrorAction SilentlyContinue

# Convert SQLite to SQL Dump
<#
.SYNOPSIS
    Converts SQLite database to SQL dump format.
.DESCRIPTION
    Converts a SQLite database file to SQL dump format.
    Creates a SQL script that can recreate the database.
    Requires SQLite command-line tool (sqlite3) to be installed.
.PARAMETER InputPath
    The path to the SQLite database file (.db, .sqlite, or .sqlite3 extension).
.PARAMETER OutputPath
    The path for the output SQL file. If not specified, uses input path with .sql extension.
#>
function ConvertFrom-SqliteToSql {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SqliteToSql @PSBoundParameters
}
Set-Alias -Name sqlite-to-sql -Value ConvertFrom-SqliteToSql -ErrorAction SilentlyContinue
Set-Alias -Name db-to-sql -Value ConvertFrom-SqliteToSql -ErrorAction SilentlyContinue

