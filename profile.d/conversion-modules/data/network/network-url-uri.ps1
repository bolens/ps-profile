# ===============================================
# URL/URI parsing and conversion utilities
# URL/URI ↔ Components, JSON, Query String
# ===============================================

<#
.SYNOPSIS
    Initializes URL/URI parsing and conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for URL/URI parsing and conversion.
    Supports parsing URLs/URIs into components (scheme, host, path, query, fragment) and converting between formats.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    URL/URI format follows RFC 3986 specification.
    Components: scheme://[userinfo@]host[:port][/path][?query][#fragment]
#>
function Initialize-FileConversion-NetworkUrlUri {
    # Parse URL/URI into components
    Set-Item -Path Function:Global:_Parse-UrlUri -Value {
        param([string]$Url)
        if ([string]::IsNullOrWhiteSpace($Url)) {
            return $null
        }
        
        try {
            $uri = [System.Uri]::new($Url)
            
            $result = @{
                Original    = $Url
                Scheme      = $uri.Scheme
                Host        = $uri.Host
                Port        = if ($uri.Port -ne -1) { $uri.Port } else { $null }
                Path        = $uri.AbsolutePath
                Query       = $uri.Query
                Fragment    = $uri.Fragment
                UserInfo    = $uri.UserInfo
                Authority   = $uri.Authority
                AbsoluteUri = $uri.AbsoluteUri
            }
            
            # Parse query string if present
            if ($uri.Query -and $uri.Query.Length -gt 1) {
                $queryString = $uri.Query.Substring(1)  # Remove leading ?
                $queryParams = @{}
                $pairs = $queryString -split '&'
                foreach ($pair in $pairs) {
                    if ($pair -match '^([^=]+)=(.*)$') {
                        $key = [System.Uri]::UnescapeDataString($matches[1])
                        $value = [System.Uri]::UnescapeDataString($matches[2])
                        if ($queryParams.ContainsKey($key)) {
                            # Multiple values - convert to array
                            if ($queryParams[$key] -is [System.Array]) {
                                $queryParams[$key] += $value
                            }
                            else {
                                $queryParams[$key] = @($queryParams[$key], $value)
                            }
                        }
                        else {
                            $queryParams[$key] = $value
                        }
                    }
                    elseif ($pair.Length -gt 0) {
                        # Key without value
                        $key = [System.Uri]::UnescapeDataString($pair)
                        $queryParams[$key] = $null
                    }
                }
                $result.QueryParameters = $queryParams
            }
            else {
                $result.QueryParameters = @{}
            }
            
            return $result
        }
        catch {
            throw "Failed to parse URL/URI: $_"
        }
    } -Force

    # Build URL/URI from components
    Set-Item -Path Function:Global:_Build-UrlUri -Value {
        param([hashtable]$Components)
        if ($null -eq $Components) {
            return ''
        }
        
        try {
            $builder = [System.UriBuilder]::new()
            
            if ($Components.ContainsKey('Scheme')) {
                $builder.Scheme = $Components.Scheme
            }
            if ($Components.ContainsKey('Host')) {
                $builder.Host = $Components.Host
            }
            if ($Components.ContainsKey('Port') -and $null -ne $Components.Port) {
                $builder.Port = $Components.Port
            }
            if ($Components.ContainsKey('Path')) {
                $builder.Path = $Components.Path
            }
            if ($Components.ContainsKey('Fragment') -and $Components.Fragment) {
                $fragment = $Components.Fragment
                if (-not $fragment.StartsWith('#')) {
                    $fragment = '#' + $fragment
                }
                $builder.Fragment = $fragment
            }
            
            # Build query string from QueryParameters if provided
            if ($Components.ContainsKey('QueryParameters') -and $Components.QueryParameters) {
                $queryPairs = @()
                foreach ($key in $Components.QueryParameters.Keys) {
                    $value = $Components.QueryParameters[$key]
                    $encodedKey = [System.Uri]::EscapeDataString($key)
                    if ($null -eq $value) {
                        $queryPairs += $encodedKey
                    }
                    elseif ($value -is [System.Array]) {
                        foreach ($v in $value) {
                            $encodedValue = [System.Uri]::EscapeDataString($v)
                            $queryPairs += "$encodedKey=$encodedValue"
                        }
                    }
                    else {
                        $encodedValue = [System.Uri]::EscapeDataString($value)
                        $queryPairs += "$encodedKey=$encodedValue"
                    }
                }
                if ($queryPairs.Count -gt 0) {
                    $builder.Query = $queryPairs -join '&'
                }
            }
            elseif ($Components.ContainsKey('Query') -and $Components.Query) {
                $query = $Components.Query
                if ($query.StartsWith('?')) {
                    $builder.Query = $query.Substring(1)
                }
                else {
                    $builder.Query = $query
                }
            }
            
            return $builder.Uri.ToString()
        }
        catch {
            throw "Failed to build URL/URI: $_"
        }
    } -Force

    # URL/URI to JSON
    Set-Item -Path Function:Global:_ConvertFrom-UrlUriToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(url|uri)$', '.json'
            }
            
            $urlContent = Get-Content -LiteralPath $InputPath -Raw
            $url = $urlContent.Trim()
            
            $parsed = _Parse-UrlUri -Url $url
            
            # Convert to JSON
            $jsonObj = [PSCustomObject]$parsed
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert URL/URI to JSON: $_"
            throw
        }
    } -Force

    # JSON to URL/URI
    Set-Item -Path Function:Global:_ConvertTo-UrlUriFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.url'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable
            $components = @{
                Scheme = $jsonObj.Scheme
                Host   = $jsonObj.Host
            }
            
            if ($jsonObj.Port) {
                $components.Port = $jsonObj.Port
            }
            if ($jsonObj.Path) {
                $components.Path = $jsonObj.Path
            }
            if ($jsonObj.Fragment) {
                $components.Fragment = $jsonObj.Fragment
            }
            if ($jsonObj.QueryParameters) {
                $components.QueryParameters = @{}
                $jsonObj.QueryParameters.PSObject.Properties | ForEach-Object {
                    $components.QueryParameters[$_.Name] = $_.Value
                }
            }
            
            $url = _Build-UrlUri -Components $components
            Set-Content -LiteralPath $OutputPath -Value $url -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to URL/URI: $_"
            throw
        }
    } -Force
}

# Parse URL/URI into components
<#
.SYNOPSIS
    Parses a URL/URI into its components.
.DESCRIPTION
    Parses a URL/URI string into its components (scheme, host, port, path, query, fragment, etc.)
    and returns a structured object with all components.
.PARAMETER Url
    The URL/URI string to parse.
.EXAMPLE
    Parse-UrlUri -Url "https://example.com:8080/path?key=value#fragment"
    
    Parses the URL and returns components.
.EXAMPLE
    "https://example.com/path" | Parse-UrlUri
    
    Parses URL from pipeline.
.OUTPUTS
    PSCustomObject
    Returns an object with properties: Scheme, Host, Port, Path, Query, Fragment, QueryParameters, etc.
#>
function Parse-UrlUri {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Url
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($Url)) {
            return $null
        }
        try {
            if (Get-Command _Parse-UrlUri -ErrorAction SilentlyContinue) {
                $parsed = _Parse-UrlUri -Url $Url
                return [PSCustomObject]$parsed
            }
            else {
                Write-Error "Internal parsing function _Parse-UrlUri not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to parse URL/URI: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name parse-url -Value Parse-UrlUri -ErrorAction SilentlyContinue
Set-Alias -Name parse-uri -Value Parse-UrlUri -ErrorAction SilentlyContinue

# Build URL/URI from components
<#
.SYNOPSIS
    Builds a URL/URI from components.
.DESCRIPTION
    Constructs a URL/URI string from a hashtable or object containing URL components.
.PARAMETER Components
    Hashtable or object with URL components: Scheme, Host, Port, Path, Query, Fragment, QueryParameters.
.EXAMPLE
    $components = @{
        Scheme = 'https'
        Host = 'example.com'
        Path = '/api/users'
        QueryParameters = @{ id = '123' }
    }
    Build-UrlUri -Components $components
    
    Builds URL from components.
.OUTPUTS
    System.String
    Returns the constructed URL/URI string.
#>
function Build-UrlUri {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Components
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _Build-UrlUri -ErrorAction SilentlyContinue) {
            return _Build-UrlUri -Components $Components
        }
        else {
            Write-Error "Internal building function _Build-UrlUri not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to build URL/URI: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name build-url -Value Build-UrlUri -ErrorAction SilentlyContinue
Set-Alias -Name build-uri -Value Build-UrlUri -ErrorAction SilentlyContinue

# Convert URL/URI to JSON
<#
.SYNOPSIS
    Converts URL/URI file to JSON format.
.DESCRIPTION
    Parses a URL/URI from a file and converts it to structured JSON format with all components.
.PARAMETER InputPath
    The path to the file containing the URL/URI (.url or .uri extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-UrlUriToJson -InputPath "url.url"
    
    Converts url.url to url.json.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-UrlUriToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-UrlUriToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-UrlUriToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-UrlUriToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert URL/URI to JSON: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name url-to-json -Value ConvertFrom-UrlUriToJson -ErrorAction SilentlyContinue
Set-Alias -Name uri-to-json -Value ConvertFrom-UrlUriToJson -ErrorAction SilentlyContinue

# Convert JSON to URL/URI
<#
.SYNOPSIS
    Converts JSON file to URL/URI format.
.DESCRIPTION
    Converts a structured JSON file (with URL components) to URL/URI format.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output URL/URI file. If not specified, uses input path with .url extension.
.EXAMPLE
    ConvertTo-UrlUriFromJson -InputPath "url.json"
    
    Converts url.json to url.url.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-UrlUriFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertTo-UrlUriFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-UrlUriFromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-UrlUriFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to URL/URI: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-url -Value ConvertTo-UrlUriFromJson -ErrorAction SilentlyContinue
Set-Alias -Name json-to-uri -Value ConvertTo-UrlUriFromJson -ErrorAction SilentlyContinue

