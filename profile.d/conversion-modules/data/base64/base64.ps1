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
            # Parse debug level once at function start
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                # Debug is enabled
            }
            
            try {
                # Level 1: Basic operation start
                if ($debugLevel -ge 1) {
                    $inputType = if ($InputObject -is [byte[]]) { 'byte[]' } else { 'string' }
                    Write-Verbose "[conversion.base64.encode] Starting encoding, input type: $inputType"
                }
                
                $encodeStartTime = Get-Date
                if ($InputObject -is [byte[]]) {
                    $result = [Convert]::ToBase64String($InputObject)
                    $inputSize = $InputObject.Length
                }
                else {
                    $text = [string]$InputObject
                    $bytes = [Text.Encoding]::UTF8.GetBytes($text)
                    $inputSize = $bytes.Length
                    $result = [Convert]::ToBase64String($bytes)
                }
                $encodeDuration = ((Get-Date) - $encodeStartTime).TotalMilliseconds
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.base64.encode] Encoding completed in ${encodeDuration}ms"
                    Write-Verbose "[conversion.base64.encode] Input size: ${inputSize} bytes, Output length: $($result.Length) characters"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    Write-Host "  [conversion.base64.encode] Performance - Duration: ${encodeDuration}ms, Input: ${inputSize} bytes, Output: $($result.Length) characters" -ForegroundColor DarkGray
                }
                
                return $result
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    $inputType = if ($InputObject -is [byte[]]) { 'byte[]' } else { 'string' }
                    $inputSize = if ($InputObject -is [byte[]]) { $InputObject.Length } elseif ($InputObject) { ([string]$InputObject).Length } else { 0 }
                    Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.base64.encode' -Context @{
                        input_type = $inputType
                        input_size_bytes = $inputSize
                        error_type = $_.Exception.GetType().FullName
                    }
                }
                else {
                    Write-Error "Failed to encode to base64: $_"
                }
                
                # Level 2: Error details
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.base64.encode] Error type: $($_.Exception.GetType().FullName)"
                }
                
                # Level 3: Stack trace
                if ($debugLevel -ge 3) {
                    Write-Host "  [conversion.base64.encode] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
                
                throw
            }
        }
    } -Force

    # Base64 decode
    Set-Item -Path Function:Global:_ConvertFrom-Base64 -Value {
        param([Parameter(ValueFromPipeline = $true)] $InputObject)
        process {
            # Parse debug level once at function start
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                # Debug is enabled
            }
            
            $s = [string]$InputObject -replace '\s+', ''
            if ([string]::IsNullOrWhiteSpace($s)) {
                return ''
            }
            
            try {
                # Level 1: Basic operation start
                if ($debugLevel -ge 1) {
                    Write-Verbose "[conversion.base64.decode] Starting decoding, input length: $($s.Length) characters"
                }
                
                $decodeStartTime = Get-Date
                $bytes = [Convert]::FromBase64String($s)
                $result = [Text.Encoding]::UTF8.GetString($bytes)
                $decodeDuration = ((Get-Date) - $decodeStartTime).TotalMilliseconds
                
                # Level 2: Timing information
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.base64.decode] Decoding completed in ${decodeDuration}ms"
                    Write-Verbose "[conversion.base64.decode] Input length: $($s.Length) characters, Output size: $($bytes.Length) bytes, Result length: $($result.Length) characters"
                }
                
                # Level 3: Performance breakdown
                if ($debugLevel -ge 3) {
                    Write-Host "  [conversion.base64.decode] Performance - Duration: ${decodeDuration}ms, Input: $($s.Length) characters, Output: $($bytes.Length) bytes, Result: $($result.Length) characters" -ForegroundColor DarkGray
                }
                
                return $result
            }
            catch {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.base64.decode' -Context @{
                        input_length = $s.Length
                        error_type = $_.Exception.GetType().FullName
                    }
                }
                else {
                    Write-Error "Invalid base64 input: $_" -ErrorAction SilentlyContinue
                }
                
                # Level 2: Error details
                if ($debugLevel -ge 2) {
                    Write-Verbose "[conversion.base64.decode] Error type: $($_.Exception.GetType().FullName)"
                }
                
                # Level 3: Stack trace
                if ($debugLevel -ge 3) {
                    Write-Host "  [conversion.base64.decode] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
                
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
    
    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }
    
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    try {
        $result = & "Global:_ConvertFrom-Base64" @PSBoundParameters
        return $result
    }
    catch {
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            $inputLength = if ($InputObject) { ([string]$InputObject -replace '\s+', '').Length } else { 0 }
            Write-StructuredError -ErrorRecord $_ -OperationName 'conversion.base64.decode' -Context @{
                input_length = $inputLength
                error_type = $_.Exception.GetType().FullName
            }
        }
        else {
            Write-Error "Failed to decode from base64: $($_.Exception.Message)" -ErrorAction SilentlyContinue
        }
        
        # Level 2: Error details
        if ($debugLevel -ge 2) {
            Write-Verbose "[conversion.base64.decode] Error type: $($_.Exception.GetType().FullName)"
        }
        
        # Level 3: Stack trace
        if ($debugLevel -ge 3) {
            Write-Host "  [conversion.base64.decode] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }
        
        return $null
    }
}
Set-Alias -Name from-base64 -Value ConvertFrom-Base64 -Scope Global -ErrorAction SilentlyContinue

