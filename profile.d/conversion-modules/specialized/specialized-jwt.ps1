# ===============================================
# JWT (JSON Web Token) conversion utilities
# JWT ↔ JSON, Object
# ===============================================

<#
.SYNOPSIS
    Initializes JWT conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for JWT (JSON Web Token) format conversions.
    Supports encoding JSON to JWT tokens and decoding JWT tokens to JSON.
    This function is called automatically by Ensure-FileConversion-Specialized.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and jsonwebtoken package for encoding.
    Decoding can be done in pure PowerShell (no signature verification).
#>
function Initialize-FileConversion-SpecializedJwt {
    # Ensure dev-tools JWT functions are available
    if (-not $global:DevToolsInitialized) {
        # Try to ensure dev tools are loaded
        if (Get-Command Ensure-DevTools -ErrorAction SilentlyContinue) {
            Ensure-DevTools | Out-Null
        }
    }

    # JSON to JWT
    Set-Item -Path Function:Global:_ConvertTo-JwtFromJson -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Secret)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.jwt'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            
            # Convert to hashtable
            $payload = @{}
            $jsonObj.PSObject.Properties | ForEach-Object {
                $payload[$_.Name] = $_.Value
            }
            
            # Use existing JWT encoding function if available
            if (Get-Command _Encode-Jwt -ErrorAction SilentlyContinue) {
                $token = _Encode-Jwt -Payload $payload -Secret $Secret
            }
            elseif (Get-Command Encode-Jwt -ErrorAction SilentlyContinue) {
                $token = Encode-Jwt -Payload $payload -Secret $Secret
            }
            else {
                throw "JWT encoding function not available. Ensure dev-tools are loaded."
            }
            
            Set-Content -LiteralPath $OutputPath -Value $token -Encoding UTF8 -NoNewline
        }
        catch {
            Write-Error "Failed to convert JSON to JWT: $_"
            throw
        }
    } -Force

    # JWT to JSON
    Set-Item -Path Function:Global:_ConvertFrom-JwtToJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(jwt|token)$', '.json'
            }
            
            $token = Get-Content -LiteralPath $InputPath -Raw
            $token = $token.Trim()
            
            # Use existing JWT decoding function if available
            if (Get-Command _Decode-Jwt -ErrorAction SilentlyContinue) {
                $decoded = _Decode-Jwt -Token $token
            }
            elseif (Get-Command Decode-Jwt -ErrorAction SilentlyContinue) {
                $decoded = Decode-Jwt -Token $token
            }
            else {
                throw "JWT decoding function not available. Ensure dev-tools are loaded."
            }
            
            # Convert to JSON (include header and payload)
            $result = @{
                Header    = $decoded.Header
                Payload   = $decoded.Payload
                Signature = $decoded.Signature
            }
            $json = $result | ConvertTo-Json -Depth 100
            Set-Content -LiteralPath $OutputPath -Value $json -Encoding UTF8
        }
        catch {
            Write-Error "Failed to convert JWT to JSON: $_"
            throw
        }
    } -Force
}

# Convert JSON to JWT
<#
.SYNOPSIS
    Converts JSON file to JWT token.
.DESCRIPTION
    Reads JSON from a file and creates a JWT token with the JSON data as payload.
    Requires Node.js and jsonwebtoken package.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output JWT token file. If not specified, uses input path with .jwt extension.
.PARAMETER Secret
    Optional secret key for signing the token. If not provided, uses default secret.
.EXAMPLE
    ConvertTo-JwtFromJson -InputPath "payload.json" -Secret "mysecret"
    
    Converts payload.json to payload.jwt token.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-JwtFromJson {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$Secret = ''
    )
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertTo-JwtFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-JwtFromJson -InputPath $InputPath -OutputPath $OutputPath -Secret $Secret
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-JwtFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to JWT: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-jwt -Value ConvertTo-JwtFromJson -ErrorAction SilentlyContinue

# Convert JWT to JSON
<#
.SYNOPSIS
    Converts JWT token file to JSON format.
.DESCRIPTION
    Decodes a JWT token from a file and converts it to structured JSON format with header, payload, and signature.
    Note: This does not verify the signature, only decodes the token structure.
.PARAMETER InputPath
    The path to the JWT token file (.jwt or .token extension).
.PARAMETER OutputPath
    The path for the output JSON file. If not specified, uses input path with .json extension.
.EXAMPLE
    ConvertFrom-JwtToJson -InputPath "token.jwt"
    
    Decodes token.jwt to token.json.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertFrom-JwtToJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertFrom-JwtToJson -ErrorAction SilentlyContinue) {
            _ConvertFrom-JwtToJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-JwtToJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JWT to JSON: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name jwt-to-json -Value ConvertFrom-JwtToJson -ErrorAction SilentlyContinue

