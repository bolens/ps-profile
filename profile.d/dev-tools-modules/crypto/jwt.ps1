# ===============================================
# JWT (JSON Web Token) utilities
# ===============================================

<#
.SYNOPSIS
    Initializes JWT utility functions.
.DESCRIPTION
    Sets up internal JWT encoding and decoding functions.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and jsonwebtoken package for encoding.
#>
function Initialize-DevTools-Jwt {
    # Base64 URL encoding helper
    Set-Item -Path Function:Global:_ConvertFrom-Base64Url -Value {
        param([string]$Base64Url)
        $base64 = $Base64Url -replace '-', '+' -replace '_', '/'
        switch ($base64.Length % 4) {
            2 { $base64 += '==' }
            3 { $base64 += '=' }
        }
        [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($base64))
    } -Force

    # JWT Decoder
    Set-Item -Path Function:Global:_Decode-Jwt -Value {
        param([string]$Token)
        try {
            $parts = $Token.Split('.')
            if ($parts.Length -ne 3) {
                throw "Invalid JWT token format. Expected 3 parts separated by dots."
            }
            # Decode header
            $headerJson = $parts[0] | _ConvertFrom-Base64Url
            $header = $headerJson | ConvertFrom-Json
            # Decode payload
            $payloadJson = $parts[1] | _ConvertFrom-Base64Url
            $payload = $payloadJson | ConvertFrom-Json
            [PSCustomObject]@{
                Header    = $header
                Payload   = $payload
                Signature = $parts[2]
            }
        }
        catch {
            Write-Error "Failed to decode JWT: $_"
        }
    } -Force

    # JWT Encoder
    Set-Item -Path Function:Global:_Encode-Jwt -Value {
        param(
            [hashtable]$Payload,
            [hashtable]$Header = @{ alg = 'HS256'; typ = 'JWT' },
            [string]$Secret = ''
        )
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use JWT encoding."
            }
            $nodeScript = @"
try {
    const jwt = require('jsonwebtoken');
    const payload = JSON.parse(process.argv[1]);
    const header = JSON.parse(process.argv[2]);
    const secret = process.argv[3] || 'secret';
    const token = jwt.sign(payload, secret, { header: header });
    console.log(token);
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: jsonwebtoken package is not installed. Install it with: npm install -g jsonwebtoken');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "jwt-encode-$(Get-Random).js"
            $payloadJson = $Payload | ConvertTo-Json -Compress
            $headerJson = $Header | ConvertTo-Json -Compress
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $payloadJson, $headerJson, $Secret
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                return $result.Trim()
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to encode JWT: $_"
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Decodes a JSON Web Token (JWT).
.DESCRIPTION
    Decodes a JWT token and returns the header and payload as objects.
    Does not verify the signature, only decodes the token structure.
.PARAMETER Token
    The JWT token string to decode.
.EXAMPLE
    Decode-Jwt -Token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    Decodes the JWT token and displays header and payload.
.OUTPUTS
    PSCustomObject
    Object containing Header, Payload, and Signature properties.
#>
function Decode-Jwt {
    param([string]$Token)
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Decode-Jwt @PSBoundParameters
}
Set-Alias -Name jwt-decode -Value Decode-Jwt -ErrorAction SilentlyContinue

<#
.SYNOPSIS
    Encodes data into a JSON Web Token (JWT).
.DESCRIPTION
    Creates a JWT token from a payload and optional header.
    Requires Node.js and jsonwebtoken package.
.PARAMETER Payload
    Hashtable containing the JWT payload data.
.PARAMETER Header
    Hashtable containing the JWT header. Default includes alg and typ.
.PARAMETER Secret
    Secret key for signing the token.
.EXAMPLE
    Encode-Jwt -Payload @{sub="user123"; exp=1234567890} -Secret "mysecret"
    Creates a JWT token with the specified payload.
.OUTPUTS
    System.String
    The encoded JWT token string.
#>
function Encode-Jwt {
    param(
        [hashtable]$Payload,
        [hashtable]$Header = @{ alg = 'HS256'; typ = 'JWT' },
        [string]$Secret = ''
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _Encode-Jwt @PSBoundParameters
}
Set-Alias -Name jwt-encode -Value Encode-Jwt -ErrorAction SilentlyContinue

