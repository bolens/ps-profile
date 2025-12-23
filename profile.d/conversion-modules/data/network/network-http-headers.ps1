# ===============================================
# HTTP headers parsing and conversion utilities
# HTTP Headers ↔ JSON, Object
# ===============================================

<#
.SYNOPSIS
    Initializes HTTP headers parsing and conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HTTP headers parsing and conversion.
    Supports parsing HTTP headers and converting between header format and JSON, objects, etc.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    HTTP headers format: Header-Name: header value
    Headers are case-insensitive but typically use Title-Case for names.
#>
function Initialize-FileConversion-NetworkHttpHeaders {
    # Parse HTTP headers into hashtable
    Set-Item -Path Function:Global:_Parse-HttpHeaders -Value {
        param([string]$Headers)
        if ([string]::IsNullOrWhiteSpace($Headers)) {
            return @{}
        }
        
        $result = @{}
        $lines = $Headers -split "`r?`n", 0, 'Regex'
        
        foreach ($line in $lines) {
            $line = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }
            
            # Handle header continuation (lines starting with space or tab)
            if ($line -match '^\s') {
                # Continuation of previous header value
                if ($result.Count -gt 0) {
                    $lastKey = ($result.Keys | Select-Object -Last 1)
                    $result[$lastKey] += " " + $line.Trim()
                }
                continue
            }
            
            # Parse header: Name: Value
            if ($line -match '^([^:]+):\s*(.*)$') {
                $headerName = $matches[1].Trim()
                $headerValue = $matches[2].Trim()
                
                # HTTP header names are case-insensitive, but we'll preserve original case
                # Check if header already exists (case-insensitive)
                $existingKey = $null
                foreach ($key in $result.Keys) {
                    if ($key -eq $headerName -or $key -ieq $headerName) {
                        $existingKey = $key
                        break
                    }
                }
                
                if ($null -ne $existingKey) {
                    # Multiple values - convert to array
                    if ($result[$existingKey] -is [System.Array]) {
                        $result[$existingKey] += $headerValue
                    }
                    else {
                        $result[$existingKey] = @($result[$existingKey], $headerValue)
                    }
                }
                else {
                    $result[$headerName] = $headerValue
                }
            }
        }
        
        return $result
    } -Force

    # Build HTTP headers from hashtable
    Set-Item -Path Function:Global:_Build-HttpHeaders -Value {
        param([hashtable]$Headers)
        if ($null -eq $Headers -or $Headers.Count -eq 0) {
            return ''
        }
        
        $lines = @()
        foreach ($key in $Headers.Keys) {
            $value = $Headers[$key]
            
            if ($null -eq $value) {
                $lines += "${key}:"
            }
            elseif ($value -is [System.Array]) {
                foreach ($v in $value) {
                    $lines += "${key}: $v"
                }
            }
            else {
                $lines += "${key}: $value"
            }
        }
        
        return $lines -join "`r`n"
    } -Force

    # HTTP headers to JSON
    Set-Item -Path Function:Global:_ConvertFrom-HttpHeadersToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(headers|http)$', '.json'
            }
            
            $headersContent = Get-Content -LiteralPath $InputPath -Raw
            $parsed = _Parse-HttpHeaders -Headers $headersContent
            
            # Convert to JSON
            $jsonObj = [PSCustomObject]$parsed
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert HTTP headers to JSON: $_"
            throw
        }
    } -Force

    # JSON to HTTP headers
    Set-Item -Path Function:Global:_ConvertTo-HttpHeadersFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.headers'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable
            $headers = @{}
            $jsonObj.PSObject.Properties | ForEach-Object {
                $headers[$_.Name] = $_.Value
            }
            
            $headersString = _Build-HttpHeaders -Headers $headers
            Set-Content -LiteralPath $OutputPath -Value $headersString -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to HTTP headers: $_"
            throw
        }
    } -Force
}

# Parse HTTP headers
<#
.SYNOPSIS
    Parses HTTP headers into a hashtable.
.DESCRIPTION
    Parses HTTP headers (Header-Name: value format) into a hashtable.
    Supports multi-line header values and multiple headers with the same name.
.PARAMETER Headers
    The HTTP headers string to parse.
.EXAMPLE
    $headers = @"
Content-Type: application/json
Authorization: Bearer token123
"@
    Parse-HttpHeaders -Headers $headers
    
    Parses headers and returns hashtable.
.EXAMPLE
    Get-Content headers.txt | Parse-HttpHeaders
    
    Parses headers from pipeline.
.OUTPUTS
    Hashtable
    Returns a hashtable with header names as keys and values.
#>
function Parse-HttpHeaders {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Headers
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($Headers)) {
            return @{}
        }
        try {
            if (Get-Command _Parse-HttpHeaders -ErrorAction SilentlyContinue) {
                return _Parse-HttpHeaders -Headers $Headers
            }
            else {
                Write-Error "Internal parsing function _Parse-HttpHeaders not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to parse HTTP headers: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name parse-headers -Value Parse-HttpHeaders -ErrorAction SilentlyContinue

# Build HTTP headers
<#
.SYNOPSIS
    Builds HTTP headers from a hashtable.
.DESCRIPTION
    Constructs HTTP headers string from a hashtable or object containing header name-value pairs.
.PARAMETER Headers
    Hashtable or object with HTTP headers.
.EXAMPLE
    $headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = 'Bearer token123'
    }
    Build-HttpHeaders -Headers $headers
    
    Builds headers string from hashtable.
.OUTPUTS
    System.String
    Returns the constructed HTTP headers string.
#>
function Build-HttpHeaders {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Headers
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _Build-HttpHeaders -ErrorAction SilentlyContinue) {
            return _Build-HttpHeaders -Headers $Headers
        }
        else {
            Write-Error "Internal building function _Build-HttpHeaders not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to build HTTP headers: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name build-headers -Value Build-HttpHeaders -ErrorAction SilentlyContinue

# Convert HTTP headers to JSON
<#
.SYNOPSIS
    Converts HTTP headers file to JSON format.
.DESCRIPTION
    Parses HTTP headers from a file and converts them to structured JSON format.
.PARAMETER InputPath
    The path to the file containing HTTP headers (.headers or .http extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-HttpHeadersToJson -InputPath "headers.headers"
    
    Converts headers.headers to headers.json.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-HttpHeadersToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-HttpHeadersToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-HttpHeadersToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-HttpHeadersToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HTTP headers to JSON: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name headers-to-json -Value ConvertFrom-HttpHeadersToJson -ErrorAction SilentlyContinue

# Convert JSON to HTTP headers
<#
.SYNOPSIS
    Converts JSON file to HTTP headers format.
.DESCRIPTION
    Converts a structured JSON file (with header name-value pairs) to HTTP headers format.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output HTTP headers file. If not specified, uses input path with .headers extension.
.EXAMPLE
    ConvertTo-HttpHeadersFromJson -InputPath "headers.json"
    
    Converts headers.json to headers.headers.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-HttpHeadersFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertTo-HttpHeadersFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-HttpHeadersFromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HttpHeadersFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to HTTP headers: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-headers -Value ConvertTo-HttpHeadersFromJson -ErrorAction SilentlyContinue

