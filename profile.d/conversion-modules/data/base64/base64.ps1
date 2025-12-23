# ===============================================
# Base64 format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Base64 format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Base64 encoding and decoding.
    Supports encoding text/bytes to Base64 and decoding Base64 back to text.
    This function is called automatically by Initialize-FileConversion-CoreBasic.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-CoreBasicBase64 {
    # Base64 encode
    Set-Item -Path Function:Global:_ConvertTo-Base64 -Value {
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            if ($InputObject -is [byte[]]) {
                return [Convert]::ToBase64String($InputObject)
            }
            $text = [string]$InputObject
            $bytes = [Text.Encoding]::UTF8.GetBytes($text)
            return [Convert]::ToBase64String($bytes)
        }
    } -Force

    # Base64 decode
    Set-Item -Path Function:Global:_ConvertFrom-Base64 -Value {
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            $s = [string]$InputObject -replace '\s+', ''
            if ([string]::IsNullOrWhiteSpace($s)) {
                return ''
            }
            try {
                $bytes = [Convert]::FromBase64String($s)
                return [Text.Encoding]::UTF8.GetString($bytes)
            }
            catch {
                Write-Error "Invalid base64 input: $_" -ErrorAction SilentlyContinue
                return $null
            }
        }
    } -Force
}

# Public functions and aliases
# Encode to base64
<#
.SYNOPSIS
    Encodes input to base64 format.
.DESCRIPTION
    Converts file contents or string input to base64 encoded string.
.PARAMETER InputObject
    The file path or string to encode.
#>
function ConvertTo-Base64 {
    param([Parameter(ValueFromPipeline = $true)] $InputObject)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        & "Global:_ConvertTo-Base64" @PSBoundParameters
    }
    catch {
        Write-Error "Failed to encode to base64: $($_.Exception.Message)"
        throw
    }
}
Set-Alias -Name to-base64 -Value ConvertTo-Base64 -Scope Global -ErrorAction SilentlyContinue

# Decode from base64
<#
.SYNOPSIS
    Decodes base64 input to text.
.DESCRIPTION
    Converts base64 encoded string back to readable text.
.PARAMETER InputObject
    The base64 string to decode.
#>
function ConvertFrom-Base64 {
    param([Parameter(ValueFromPipeline = $true)] $InputObject)
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        $result = & "Global:_ConvertFrom-Base64" @PSBoundParameters
        return $result
    }
    catch {
        Write-Error "Failed to decode from base64: $($_.Exception.Message)" -ErrorAction SilentlyContinue
        return $null
    }
}
Set-Alias -Name from-base64 -Value ConvertFrom-Base64 -Scope Global -ErrorAction SilentlyContinue

