# ===============================================
# SQL Dump format conversion utilities
# SQL Dump ↔ JSON, CSV
# ===============================================

<#
.SYNOPSIS
    Initializes SQL Dump format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for SQL dump files.
    SQL dump files contain SQL statements for database creation and data insertion.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Pure PowerShell implementation - no external dependencies required.
#>
function Initialize-FileConversion-DatabaseSqlDump {
    # SQL Dump to JSON
    Set-Item -Path Function:Global:_ConvertFrom-SqlDumpToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.sql$', '.json' }
            
            $sqlContent = Get-Content -LiteralPath $InputPath -Raw -Encoding UTF8
            $result = @{}
            
            # Parse CREATE TABLE statements
            $createTablePattern = '(?i)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:\[?(\w+)\]?|`?(\w+)`?|"(\w+)")'
            $createMatches = [regex]::Matches($sqlContent, $createTablePattern)
            $tables = @{}
            foreach ($match in $createMatches) {
                $tableName = if ($match.Groups[1].Value) { $match.Groups[1].Value } 
                elseif ($match.Groups[2].Value) { $match.Groups[2].Value }
                else { $match.Groups[3].Value }
                $tables[$tableName] = @()
            }
            
            # Parse INSERT INTO statements
            $insertPattern = '(?i)INSERT\s+INTO\s+(?:\[?(\w+)\]?|`?(\w+)`?|"(\w+)")\s*\([^)]+\)\s*VALUES\s*\(([^)]+)\)'
            $insertMatches = [regex]::Matches($sqlContent, $insertPattern)
            foreach ($match in $insertMatches) {
                $tableName = if ($match.Groups[1].Value) { $match.Groups[1].Value }
                elseif ($match.Groups[2].Value) { $match.Groups[2].Value }
                else { $match.Groups[3].Value }
                $valuesStr = $match.Groups[4].Value
                
                # Parse values (simple parsing - handles quoted strings and numbers)
                $values = @()
                $currentValue = ''
                $inQuotes = $false
                $quoteChar = $null
                for ($i = 0; $i -lt $valuesStr.Length; $i++) {
                    $char = $valuesStr[$i]
                    if (-not $inQuotes -and ($char -eq "'" -or $char -eq '"')) {
                        $inQuotes = $true
                        $quoteChar = $char
                        $currentValue += $char
                    }
                    elseif ($inQuotes -and $char -eq $quoteChar) {
                        # Check if escaped
                        if ($i -gt 0 -and $valuesStr[$i - 1] -eq '\') {
                            $currentValue += $char
                        }
                        else {
                            $inQuotes = $false
                            $currentValue += $char
                        }
                    }
                    elseif (-not $inQuotes -and $char -eq ',') {
                        $values += $currentValue.Trim()
                        $currentValue = ''
                    }
                    else {
                        $currentValue += $char
                    }
                }
                if ($currentValue) {
                    $values += $currentValue.Trim()
                }
                
                # Clean values (remove quotes, handle NULL)
                $cleanValues = $values | ForEach-Object {
                    $val = $_.Trim()
                    if ($val -eq 'NULL' -or $val -eq 'null') {
                        $null
                    }
                    elseif ($val -match "^'(.+)'$" -or $val -match '^"(.+)"$') {
                        $matches[1] -replace "''", "'" -replace '""', '"'
                    }
                    elseif ($val -match '^-?\d+\.?\d*$') {
                        if ($val.Contains('.')) {
                            [double]$val
                        }
                        else {
                            [long]$val
                        }
                    }
                    else {
                        $val
                    }
                }
                
                if (-not $tables.ContainsKey($tableName)) {
                    $tables[$tableName] = @()
                }
                $tables[$tableName] += $cleanValues
            }
            
            # Convert to structured JSON
            foreach ($tableName in $tables.Keys) {
                $rows = $tables[$tableName]
                if ($rows.Count -gt 0) {
                    # Try to infer column names from first INSERT or use generic names
                    $columnCount = $rows[0].Count
                    $columns = 1..$columnCount | ForEach-Object { "column$_" }
                    
                    $tableData = @()
                    foreach ($row in $rows) {
                        $rowObj = @{}
                        for ($i = 0; $i -lt [Math]::Min($row.Count, $columns.Count); $i++) {
                            $rowObj[$columns[$i]] = $row[$i]
                        }
                        $tableData += $rowObj
                    }
                    $result[$tableName] = $tableData
                }
            }
            
            $result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert SQL Dump to JSON: $_"
            throw
        }
    } -Force

    # JSON to SQL Dump
    Set-Item -Path Function:Global:_ConvertTo-SqlDumpFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.json$', '.sql' }
            
            $jsonData = Get-Content -LiteralPath $InputPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $sqlStatements = @()
            
            if ($jsonData -is [System.Collections.Hashtable] -or $jsonData -is [PSCustomObject]) {
                # Multiple tables
                $jsonObj = if ($jsonData -is [PSCustomObject]) { $jsonData | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $jsonData }
                foreach ($tableName in $jsonObj.Keys) {
                    $tableData = $jsonObj[$tableName]
                    if ($tableData -is [Array] -and $tableData.Count -gt 0) {
                        # Get column names from first row
                        $firstRow = $tableData[0]
                        $columns = if ($firstRow -is [PSCustomObject]) {
                            ($firstRow | Get-Member -MemberType NoteProperty).Name
                        }
                        else {
                            $firstRow.Keys
                        }
                        
                        # CREATE TABLE statement
                        $createTable = "CREATE TABLE IF NOT EXISTS [$tableName] (" + 
                        ($columns | ForEach-Object { "[$_] TEXT" }) -join ', ' + ");"
                        $sqlStatements += $createTable
                        
                        # INSERT statements
                        foreach ($row in $tableData) {
                            $rowObj = if ($row -is [PSCustomObject]) { $row | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $row }
                            $values = ($columns | ForEach-Object {
                                    $val = $rowObj[$_]
                                    if ($null -eq $val) {
                                        "NULL"
                                    }
                                    elseif ($val -is [string]) {
                                        "'$($val -replace "'", "''")'"
                                    }
                                    else {
                                        $val
                                    }
                                }) -join ', '
                            $insert = "INSERT INTO [$tableName] ([$($columns -join '], [')]) VALUES ($values);"
                            $sqlStatements += $insert
                        }
                    }
                }
            }
            else {
                # Single table (array of objects)
                $tableData = if ($jsonData -is [Array]) { $jsonData } else { @($jsonData) }
                if ($tableData.Count -gt 0) {
                    $firstRow = $tableData[0]
                    $columns = if ($firstRow -is [PSCustomObject]) {
                        ($firstRow | Get-Member -MemberType NoteProperty).Name
                    }
                    else {
                        $firstRow.Keys
                    }
                    
                    $tableName = "data"
                    $createTable = "CREATE TABLE IF NOT EXISTS [$tableName] (" + 
                    ($columns | ForEach-Object { "[$_] TEXT" }) -join ', ' + ");"
                    $sqlStatements += $createTable
                    
                    foreach ($row in $tableData) {
                        $rowObj = if ($row -is [PSCustomObject]) { $row | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $row }
                        $values = ($columns | ForEach-Object {
                                $val = $rowObj[$_]
                                if ($null -eq $val) {
                                    "NULL"
                                }
                                elseif ($val -is [string]) {
                                    "'$($val -replace "'", "''")'"
                                }
                                else {
                                    $val
                                }
                            }) -join ', '
                        $insert = "INSERT INTO [$tableName] ([$($columns -join '], [')]) VALUES ($values);"
                        $sqlStatements += $insert
                    }
                }
            }
            
            $sqlStatements -join "`n" | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to SQL Dump: $_"
            throw
        }
    } -Force

    # SQL Dump to CSV
    Set-Item -Path Function:Global:_ConvertFrom-SqlDumpToCsv -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$TableName)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) { throw "Input file not found: $InputPath" }
            if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.sql$', '.csv' }
            
            # First convert to JSON, then to CSV
            $tempJson = Join-Path $env:TEMP "sql-dump-to-json-$(Get-Random).json"
            try {
                _ConvertFrom-SqlDumpToJson -InputPath $InputPath -OutputPath $tempJson
                if ($tempJson -and -not [string]::IsNullOrWhiteSpace($tempJson) -and -not (Test-Path -LiteralPath $tempJson)) {
                    throw "SQL Dump to JSON conversion failed"
                }
                
                # Convert JSON to CSV
                $jsonData = Get-Content -LiteralPath $tempJson -Raw -Encoding UTF8 | ConvertFrom-Json
                
                if ($jsonData -is [System.Collections.Hashtable] -or $jsonData -is [PSCustomObject]) {
                    $jsonObj = if ($jsonData -is [PSCustomObject]) { $jsonData | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $jsonData }
                    
                    if ($TableName -and $jsonObj.ContainsKey($TableName)) {
                        $tableData = $jsonObj[$TableName]
                    }
                    else {
                        # Use first table
                        $tableData = ($jsonObj.Values | Select-Object -First 1)
                    }
                }
                else {
                    $tableData = if ($jsonData -is [Array]) { $jsonData } else { @($jsonData) }
                }
                
                if ($tableData -and $tableData.Count -gt 0) {
                    $firstRow = $tableData[0]
                    $columns = if ($firstRow -is [PSCustomObject]) {
                        ($firstRow | Get-Member -MemberType NoteProperty).Name
                    }
                    else {
                        $firstRow.Keys
                    }
                    
                    $csvLines = @()
                    $csvLines += ($columns -join ',')
                    
                    foreach ($row in $tableData) {
                        $rowObj = if ($row -is [PSCustomObject]) { $row | ConvertTo-Json | ConvertFrom-Json -AsHashtable } else { $row }
                        $values = ($columns | ForEach-Object {
                                $val = $rowObj[$_]
                                if ($null -eq $val) {
                                    ''
                                }
                                elseif ($val -is [string] -and ($val.Contains(',') -or $val.Contains('"') -or $val.Contains("`n"))) {
                                    '"' + ($val -replace '"', '""') + '"'
                                }
                                else {
                                    $val
                                }
                            }) -join ','
                        $csvLines += $values
                    }
                    
                    $csvLines -join "`n" | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                }
                else {
                    throw "No data found in SQL dump file"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempJson -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert SQL Dump to CSV: $_"
            throw
        }
    } -Force
}

# Public functions and aliases
# Convert SQL Dump to JSON
<#
.SYNOPSIS
    Converts SQL dump file to JSON format.
.DESCRIPTION
    Converts a SQL dump file to JSON format.
    Parses SQL CREATE TABLE and INSERT statements to extract data.
    Pure PowerShell implementation - no external dependencies required.
.PARAMETER InputPath
    The path to the SQL dump file (.sql extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
#>
function ConvertFrom-SqlDumpToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SqlDumpToJson @PSBoundParameters
}
Set-Alias -Name sql-dump-to-json -Value ConvertFrom-SqlDumpToJson -ErrorAction SilentlyContinue
Set-Alias -Name sql-to-json -Value ConvertFrom-SqlDumpToJson -ErrorAction SilentlyContinue

# Convert JSON to SQL Dump
<#
.SYNOPSIS
    Converts JSON file to SQL dump format.
.DESCRIPTION
    Converts a JSON file to SQL dump format.
    Creates SQL CREATE TABLE and INSERT statements from JSON data.
    Pure PowerShell implementation - no external dependencies required.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output SQL dump file. If not specified, uses input path with .sql extension.
#>
function ConvertTo-SqlDumpFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-SqlDumpFromJson @PSBoundParameters
}
Set-Alias -Name json-to-sql-dump -Value ConvertTo-SqlDumpFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-sql -Value ConvertTo-SqlDumpFromJson -ErrorAction SilentlyContinue

# Convert SQL Dump to CSV
<#
.SYNOPSIS
    Converts SQL dump file to CSV format.
.DESCRIPTION
    Converts a SQL dump file to CSV format.
    Parses SQL INSERT statements to extract data and convert to CSV.
    Pure PowerShell implementation - no external dependencies required.
.PARAMETER InputPath
    The path to the SQL dump file (.sql extension).
.PARAMETER OutputPath
    The path for the output CSV file. If not specified, uses input path with .csv extension.
.PARAMETER TableName
    Optional. Name of the table to export. If not specified, exports the first table found.
#>
function ConvertFrom-SqlDumpToCsv {
    param([string]$InputPath, [string]$OutputPath, [string]$TableName)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-SqlDumpToCsv @PSBoundParameters
}
Set-Alias -Name sql-dump-to-csv -Value ConvertFrom-SqlDumpToCsv -ErrorAction SilentlyContinue
Set-Alias -Name sql-to-csv -Value ConvertFrom-SqlDumpToCsv -ErrorAction SilentlyContinue

