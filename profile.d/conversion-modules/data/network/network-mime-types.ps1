# ===============================================
# MIME types parsing and conversion utilities
# MIME Type ↔ Components, Extensions, JSON
# ===============================================

<#
.SYNOPSIS
    Initializes MIME types parsing and conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for MIME type parsing and conversion.
    Supports parsing MIME types and converting between MIME type format and components, file extensions, etc.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    MIME type format: type/subtype; parameter=value
    Examples: text/plain, application/json, image/png; charset=utf-8
#>
function Initialize-FileConversion-NetworkMimeTypes {
    # Common MIME type to extension mapping
    $script:MimeTypeToExtension = @{
        'text/plain'                  = @('txt')
        'text/html'                   = @('html', 'htm')
        'text/css'                    = @('css')
        'text/javascript'             = @('js', 'mjs')
        'text/json'                   = @('json')
        'text/xml'                    = @('xml')
        'text/csv'                    = @('csv')
        'text/markdown'               = @('md', 'markdown')
        'application/json'            = @('json')
        'application/xml'             = @('xml')
        'application/javascript'      = @('js')
        'application/pdf'             = @('pdf')
        'application/zip'             = @('zip')
        'application/gzip'            = @('gz')
        'application/x-tar'           = @('tar')
        'application/x-bzip2'         = @('bz2')
        'application/x-7z-compressed' = @('7z')
        'application/octet-stream'    = @('bin', 'exe')
        'image/jpeg'                  = @('jpg', 'jpeg')
        'image/png'                   = @('png')
        'image/gif'                   = @('gif')
        'image/webp'                  = @('webp')
        'image/svg+xml'               = @('svg')
        'image/bmp'                   = @('bmp')
        'image/tiff'                  = @('tiff', 'tif')
        'audio/mpeg'                  = @('mp3')
        'audio/wav'                   = @('wav')
        'audio/ogg'                   = @('ogg')
        'video/mp4'                   = @('mp4')
        'video/webm'                  = @('webm')
        'video/ogg'                   = @('ogv')
    }

    # Extension to MIME type mapping (reverse)
    $script:ExtensionToMimeType = @{}
    foreach ($mimeType in $script:MimeTypeToExtension.Keys) {
        foreach ($ext in $script:MimeTypeToExtension[$mimeType]) {
            if (-not $script:ExtensionToMimeType.ContainsKey($ext)) {
                $script:ExtensionToMimeType[$ext] = $mimeType
            }
        }
    }

    # Parse MIME type into components
    Set-Item -Path Function:Global:_Parse-MimeType -Value {
        param([string]$MimeType)
        if ([string]::IsNullOrWhiteSpace($MimeType)) {
            return $null
        }
        
        $mime = $MimeType.Trim()
        $result = @{
            Original   = $mime
            Type       = ''
            Subtype    = ''
            Parameters = @{}
        }
        
        # Split by ; to separate type/subtype from parameters
        $parts = $mime -split ';', 2
        $typePart = $parts[0].Trim()
        
        # Parse type/subtype
        if ($typePart -match '^([^/]+)/(.+)$') {
            $result.Type = $matches[1].Trim()
            $result.Subtype = $matches[2].Trim()
        }
        else {
            # Invalid format
            $result.Type = $typePart
            $result.Subtype = ''
        }
        
        # Parse parameters
        if ($parts.Count -gt 1) {
            $paramString = $parts[1].Trim()
            $params = $paramString -split ',', 0, 'Regex'
            foreach ($param in $params) {
                $param = $param.Trim()
                if ($param -match '^([^=]+)=(.*)$') {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    # Remove quotes if present
                    if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                        $value = $value.Substring(1, $value.Length - 2)
                    }
                    $result.Parameters[$key] = $value
                }
            }
        }
        
        return $result
    } -Force

    # Build MIME type from components
    Set-Item -Path Function:Global:_Build-MimeType -Value {
        param([hashtable]$Components)
        if ($null -eq $Components) {
            return ''
        }
        
        if (-not $Components.ContainsKey('Type') -or -not $Components.ContainsKey('Subtype')) {
            return ''
        }
        
        $mimeType = "$($Components.Type)/$($Components.Subtype)"
        
        # Add parameters
        if ($Components.ContainsKey('Parameters') -and $Components.Parameters.Count -gt 0) {
            $params = @()
            foreach ($key in $Components.Parameters.Keys) {
                $value = $Components.Parameters[$key]
                $params += "$key=$value"
            }
            if ($params.Count -gt 0) {
                $mimeType += '; ' + ($params -join '; ')
            }
        }
        
        return $mimeType
    } -Force

    # MIME type to JSON
    Set-Item -Path Function:Global:_ConvertFrom-MimeTypeToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(mime|mimetype)$', '.json'
            }
            
            $mimeContent = Get-Content -LiteralPath $InputPath -Raw
            $mime = $mimeContent.Trim()
            
            $parsed = _Parse-MimeType -MimeType $mime
            
            # Add extensions if available
            $fullMime = "$($parsed.Type)/$($parsed.Subtype)"
            if ($script:MimeTypeToExtension.ContainsKey($fullMime)) {
                $parsed.Extensions = $script:MimeTypeToExtension[$fullMime]
            }
            
            # Convert to JSON
            $jsonObj = [PSCustomObject]$parsed
            $json = $jsonObj | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert MIME type to JSON: $_"
            throw
        }
    } -Force

    # JSON to MIME type
    Set-Item -Path Function:Global:_ConvertTo-MimeTypeFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.mime'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable
            $components = @{
                Type    = $jsonObj.Type
                Subtype = $jsonObj.Subtype
            }
            
            if ($jsonObj.Parameters) {
                $components.Parameters = @{}
                $jsonObj.Parameters.PSObject.Properties | ForEach-Object {
                    $components.Parameters[$_.Name] = $_.Value
                }
            }
            
            $mimeType = _Build-MimeType -Components $components
            Set-Content -LiteralPath $OutputPath -Value $mimeType -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JSON to MIME type: $_"
            throw
        }
    } -Force
}

# Parse MIME type
<#
.SYNOPSIS
    Parses a MIME type into its components.
.DESCRIPTION
    Parses a MIME type string (type/subtype; parameter=value) into its components.
.PARAMETER MimeType
    The MIME type string to parse.
.EXAMPLE
    Parse-MimeType -MimeType "application/json; charset=utf-8"
    
    Parses MIME type and returns components.
.EXAMPLE
    "text/html" | Parse-MimeType
    
    Parses MIME type from pipeline.
.OUTPUTS
    PSCustomObject
    Returns an object with properties: Type, Subtype, Parameters, Extensions.
#>
function Parse-MimeType {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$MimeType
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($MimeType)) {
            return $null
        }
        try {
            if (Get-Command _Parse-MimeType -ErrorAction SilentlyContinue) {
                $parsed = _Parse-MimeType -MimeType $MimeType
                # Add extensions if available
                $fullMime = "$($parsed.Type)/$($parsed.Subtype)"
                if ($script:MimeTypeToExtension.ContainsKey($fullMime)) {
                    $parsed.Extensions = $script:MimeTypeToExtension[$fullMime]
                }
                return [PSCustomObject]$parsed
            }
            else {
                Write-Error "Internal parsing function _Parse-MimeType not available" -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to parse MIME type: $_" -ErrorAction SilentlyContinue
        }
    }
}
Set-Alias -Name parse-mime -Value Parse-MimeType -ErrorAction SilentlyContinue

# Get MIME type from file extension
<#
.SYNOPSIS
    Gets MIME type from a file extension.
.DESCRIPTION
    Returns the MIME type associated with a given file extension.
.PARAMETER Extension
    The file extension (with or without leading dot).
.EXAMPLE
    Get-MimeTypeFromExtension -Extension "json"
    
    Returns "application/json".
.EXAMPLE
    ".html" | Get-MimeTypeFromExtension
    
    Returns "text/html" from pipeline.
.OUTPUTS
    System.String
    Returns the MIME type string, or empty string if not found.
#>
function Get-MimeTypeFromExtension {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Extension
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($Extension)) {
            return ''
        }
        $ext = $Extension.Trim()
        if ($ext.StartsWith('.')) {
            $ext = $ext.Substring(1)
        }
        $ext = $ext.ToLower()
        
        if ($script:ExtensionToMimeType.ContainsKey($ext)) {
            return $script:ExtensionToMimeType[$ext]
        }
        return ''
    }
}
Set-Alias -Name mime-from-ext -Value Get-MimeTypeFromExtension -ErrorAction SilentlyContinue

# Get file extension from MIME type
<#
.SYNOPSIS
    Gets file extension(s) from a MIME type.
.DESCRIPTION
    Returns the file extension(s) associated with a given MIME type.
.PARAMETER MimeType
    The MIME type string.
.EXAMPLE
    Get-ExtensionFromMimeType -MimeType "application/json"
    
    Returns "json".
.EXAMPLE
    "image/png" | Get-ExtensionFromMimeType
    
    Returns "png" from pipeline.
.OUTPUTS
    System.String[] or System.String
    Returns the file extension(s), or empty array if not found.
#>
function Get-ExtensionFromMimeType {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$MimeType
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    process {
        if ([string]::IsNullOrWhiteSpace($MimeType)) {
            return @()
        }
        $mime = $MimeType.Trim()
        # Remove parameters if present
        if ($mime -match '^([^;]+)') {
            $mime = $matches[1].Trim()
        }
        
        if ($script:MimeTypeToExtension.ContainsKey($mime)) {
            $exts = $script:MimeTypeToExtension[$mime]
            if ($exts.Count -eq 1) {
                return $exts[0]
            }
            return $exts
        }
        return @()
    }
}
Set-Alias -Name ext-from-mime -Value Get-ExtensionFromMimeType -ErrorAction SilentlyContinue

# Convert MIME type to JSON
<#
.SYNOPSIS
    Converts MIME type file to JSON format.
.DESCRIPTION
    Parses a MIME type from a file and converts it to structured JSON format.
.PARAMETER InputPath
    The path to the file containing the MIME type (.mime or .mimetype extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-MimeTypeToJson -InputPath "mime.mime"
    
    Converts mime.mime to mime.json.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-MimeTypeToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertFrom-MimeTypeToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-MimeTypeToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-MimeTypeToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert MIME type to JSON: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name mime-to-json -Value ConvertFrom-MimeTypeToJson -ErrorAction SilentlyContinue

# Convert JSON to MIME type
<#
.SYNOPSIS
    Converts JSON file to MIME type format.
.DESCRIPTION
    Converts a structured JSON file (with MIME type components) to MIME type format.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output MIME type file. If not specified, uses input path with .mime extension.
.EXAMPLE
    ConvertTo-MimeTypeFromJson -InputPath "mime.json"
    
    Converts mime.json to mime.mime.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-MimeTypeFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        if (Get-Command _ConvertTo-MimeTypeFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-MimeTypeFromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-MimeTypeFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to MIME type: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-mime -Value ConvertTo-MimeTypeFromJson -ErrorAction SilentlyContinue

