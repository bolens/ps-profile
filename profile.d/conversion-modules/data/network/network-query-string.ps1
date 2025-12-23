# ===============================================
# Query string parsing and conversion utilities
# Query String ↔ JSON, Object, Key-Value Pairs
# ===============================================

<#
.SYNOPSIS
    Initializes query string parsing and conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for URL query string parsing and conversion.
    Supports parsing query strings and converting between query string format and JSON, objects, etc.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Query string format: key1=value1&key2=value2&key3=value3
    Supports multiple values for the same key (key=value1&key=value2).
#>
function Initialize-FileConversion-NetworkQueryString {
    # Parse query string into hashtable
    Set-Item -Path Function:Global:_Parse-QueryString -Value {
        param([string]$QueryString)
        if ([string]::IsNullOrWhiteSpace($QueryString)) {
            return @{}
        }
        
        # Remove leading ? if present
        $query = $QueryString.Trim()
        if ($query.StartsWith('?')) {
            $query = $query.Substring(1)
        }
        
        $result = @{}
        if ([string]::IsNullOrWhiteSpace($query)) {
            return $result
        }
        
        # Split by &
        $pairs = $query -split '&', 0, 'Regex'
        foreach ($pair in $pairs) {
            if ([string]::IsNullOrWhiteSpace($pair)) {
                continue
            }
            
            if ($pair -match '^([^=]+)=(.*)$') {
                $key = [System.Uri]::UnescapeDataString($matches[1])
                $value = [System.Uri]::UnescapeDataString($matches[2])
                
                if ($result.ContainsKey($key)) {
                    # Multiple values - convert to array
                    if ($result[$key] -is [System.Array]) {
                        $result[$key] += $value
                    }
                    else {
                        $result[$key] = @($result[$key], $value)
                    }
                }
                else {
                    $result[$key] = $value
                }
            }
            elseif ($pair.Length -gt 0) {
                # Key without value
                $key = [System.Uri]::UnescapeDataString($pair)
                $result[$key] = $null
            }
        }
        
        return $result
    } -Force

    # Build query string from hashtable
    Set-Item -Path Function:Global:_Build-QueryString -Value {
        param([hashtable]$Parameters)
        if ($null -eq $Parameters -or $Parameters.Count -eq 0) {
            return ''
        }
        
        $pairs = @()
        foreach ($key in $Parameters.Keys) {
            $value = $Parameters[$key]
            $encodedKey = [System.Uri]::EscapeDataString($key)
            
            if ($null -eq $value) {
                $pairs += $encodedKey
            }
            elseif ($value -is [System.Array]) {
                foreach ($v in $value) {
                    $encodedValue = [System.Uri]::EscapeDataString($v)
                    $pairs += "$encodedKey=$encodedValue"
                }
            }
            else {
                $encodedValue = [System.Uri]::EscapeDataString($value)
                $pairs += "$encodedKey=$encodedValue"
            }
        }
        
        return $pairs -join '&'
    } -Force

    # Query string to JSON
    Set-Item -Path Function:Global:_ConvertFrom-QueryStringToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(query|qs)$', '.json'
            }
            
            $queryContent = Get-Content -LiteralPath $InputPath -Raw
            $parsed = _Parse-QueryString -QueryString $queryContent
            
            # Convert to JSON
            $jsonObj = [PSCustomObject]$parsed
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert query string to JSON: $_"
            throw
        }
    } -Force

    # JSON to Query string
    Set-Item -Path Function:Global:_ConvertTo-QueryStringFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.query'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable
            $parameters = @{}
            $jsonObj.PSObject.Properties | ForEach-Object {
                $parameters[$_.Name] = $_.Value
            }
            
            $queryString = _Build-QueryString -Parameters $parameters
            Set-Content -LiteralPath $OutputPath -Value $queryString -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to query string: $_"
            throw
        }
    } -Force
}

# Parse query string
<#
.SYNOPSIS
    Parses a query string into a hashtable.
.DESCRIPTION
    Parses a URL query string (key1=value1&key2=value2) into a hashtable with decoded keys and values.
    Supports multiple values for the same key.
.PARAMETER QueryString
    The query string to parse (with or without leading ?).
.EXAMPLE
    Parse-QueryString -QueryString "name=John&age=30&city=New York"
    
    Parses query string and returns hashtable.
.EXAMPLE
    "key1=value1&key2=value2" | Parse-QueryString
    
    Parses query string from pipeline.
.OUTPUTS
    Hashtable
    Returns a hashtable with query parameters as keys and values.
#>
function Parse-QueryString {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$QueryString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($QueryString)) {
            return @{}
        }
        try {
            if (Get-Command _Parse-QueryString -ErrorAction SilentlyContinue) {
                return _Parse-QueryString -QueryString $QueryString
            }
            else {
                Write-Error "Internal parsing function _Parse-QueryString not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to parse query string: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name parse-query -Value Parse-QueryString -ErrorAction SilentlyContinue

# Build query string
<#
.SYNOPSIS
    Builds a query string from a hashtable.
.DESCRIPTION
    Constructs a URL query string from a hashtable or object containing key-value pairs.
.PARAMETER Parameters
    Hashtable or object with query parameters.
.EXAMPLE
    $params = @{
        name = 'John'
        age = '30'
        city = 'New York'
    }
    Build-QueryString -Parameters $params
    
    Builds query string from parameters.
.OUTPUTS
    System.String
    Returns the constructed query string.
#>
function Build-QueryString {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Parameters
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _Build-QueryString -ErrorAction SilentlyContinue) {
            return _Build-QueryString -Parameters $Parameters
        }
        else {
            Write-Error "Internal building function _Build-QueryString not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to build query string: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name build-query -Value Build-QueryString -ErrorAction SilentlyContinue

# Convert query string to JSON
<#
.SYNOPSIS
    Converts query string file to JSON format.
.DESCRIPTION
    Parses a query string from a file and converts it to structured JSON format.
.PARAMETER InputPath
    The path to the file containing the query string (.query or .qs extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-QueryStringToJson -InputPath "query.query"
    
    Converts query.query to query.json.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-QueryStringToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-QueryStringToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-QueryStringToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-QueryStringToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert query string to JSON: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name query-to-json -Value ConvertFrom-QueryStringToJson -ErrorAction SilentlyContinue

# Convert JSON to query string
<#
.SYNOPSIS
    Converts JSON file to query string format.
.DESCRIPTION
    Converts a structured JSON file (with key-value pairs) to query string format.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output query string file. If not specified, uses input path with .query extension.
.EXAMPLE
    ConvertTo-QueryStringFromJson -InputPath "params.json"
    
    Converts params.json to params.query.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-QueryStringFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertTo-QueryStringFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-QueryStringFromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-QueryStringFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to query string: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-query -Value ConvertTo-QueryStringFromJson -ErrorAction SilentlyContinue

