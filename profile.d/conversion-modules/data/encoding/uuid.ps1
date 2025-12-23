# ===============================================
# UUID (Universally Unique Identifier) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes UUID format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for UUID (Universally Unique Identifier) format conversions.
    Supports conversions between UUID formats: standard format, hex (no dashes), Base64, Base32, and binary.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    UUID format: 8-4-4-4-12 hexadecimal digits (e.g., 550e8400-e29b-41d4-a716-446655440000)
#>
function Initialize-FileConversion-CoreEncodingUuid {
    # UUID to Hex (no dashes)
    Set-Item -Path Function:Global:_ConvertFrom-UuidToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Uuid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Uuid)) { return }
            try {
                # Remove dashes and convert to uppercase
                $hex = $Uuid -replace '-', '' -replace '\s+', ''
                if ($hex.Length -ne 32) {
                    throw "Invalid UUID format: expected 32 hex characters"
                }
                if ($hex -notmatch '^[0-9A-Fa-f]{32}$') {
                    throw "Invalid UUID format: contains non-hexadecimal characters"
                }
                return $hex.ToUpper()

            }
            catch {
                throw "Failed to convert UUID to hex: $_"
            }
        }
    } -Force

    # Hex (no dashes) to UUID
    Set-Item -Path Function:Global:_ConvertTo-UuidFromHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Hex
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Hex)) { return }
            try {
                # Remove spaces and ensure uppercase
                $hex = $Hex -replace '\s+', '' -replace '-', ''
                if ($hex.Length -ne 32) {
                    throw "Invalid hex string: expected 32 hex characters"
                }
                if ($hex -notmatch '^[0-9A-Fa-f]{32}$') {
                    throw "Invalid hex string: contains non-hexadecimal characters"
                }
                # Format as UUID: 8-4-4-4-12
                return "$($hex.Substring(0, 8))-$($hex.Substring(8, 4))-$($hex.Substring(12, 4))-$($hex.Substring(16, 4))-$($hex.Substring(20, 12))"
            }
            catch {
                throw "Failed to convert hex to UUID: $_"
            }
        }
    } -Force

    # UUID to Base64
    Set-Item -Path Function:Global:_ConvertFrom-UuidToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Uuid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Uuid)) { return }
            try {
                $hex = _ConvertFrom-UuidToHex -Uuid $Uuid
                $bytes = for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                return [Convert]::ToBase64String($bytes)

            }
            catch {
                throw "Failed to convert UUID to Base64: $_"
            }
        }
    } -Force

    # Base64 to UUID
    Set-Item -Path Function:Global:_ConvertTo-UuidFromBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Base64
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Base64)) { return }
            try {
                $bytes = [Convert]::FromBase64String($Base64.Trim())
                if ($bytes.Length -ne 16) {
                    throw "Invalid Base64: expected 16 bytes for UUID"
                }
                $hex = ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
                Write-Output (_ConvertTo-UuidFromHex -Hex $hex)
            }
            catch {
                throw "Failed to convert Base64 to UUID: $_"
            }
        }
    } -Force

    # UUID to Base32
    Set-Item -Path Function:Global:_ConvertFrom-UuidToBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Uuid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Uuid)) { return }
            try {
                # Use existing Base32 conversion if available
                if (Get-Command _ConvertFrom-HexToBase32 -ErrorAction SilentlyContinue) {
                    $hex = _ConvertFrom-UuidToHex -Uuid $Uuid
                    Write-Output (_ConvertFrom-HexToBase32 -InputObject $hex)
                }
                else {
                    throw "Base32 conversion not available. Ensure core-encoding-base32.ps1 is loaded."
                }
            }
            catch {
                throw "Failed to convert UUID to Base32: $_"
            }
        }
    } -Force

    # Base32 to UUID
    Set-Item -Path Function:Global:_ConvertTo-UuidFromBase32 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Base32
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Base32)) { return }
            try {
                # Use existing Base32 conversion if available
                if (Get-Command _ConvertFrom-Base32ToHex -ErrorAction SilentlyContinue) {
                    $hex = _ConvertFrom-Base32ToHex -InputObject $Base32
                    Write-Output (_ConvertTo-UuidFromHex -Hex $hex)
                }
                else {
                    throw "Base32 conversion not available. Ensure core-encoding-base32.ps1 is loaded."
                }
            }
            catch {
                throw "Failed to convert Base32 to UUID: $_"
            }
        }
    } -Force

    # Generate new UUID
    Set-Item -Path Function:Global:_New-Uuid -Value {
        param(
            [switch]$AsHex,
            [switch]$AsBase64,
            [switch]$AsBase32
        )
        try {
            $guid = [Guid]::NewGuid()
            $uuid = $guid.ToString()
            
            if ($AsHex) {
                _ConvertFrom-UuidToHex -Uuid $uuid
            }
            elseif ($AsBase64) {
                _ConvertFrom-UuidToBase64 -Uuid $uuid
            }
            elseif ($AsBase32) {
                _ConvertFrom-UuidToBase32 -Uuid $uuid
            }
            else {
                return $uuid
            }
        }
        catch {
            throw "Failed to generate UUID: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert UUID to Hex
<#
.SYNOPSIS
    Converts a UUID to hexadecimal format (no dashes).
.DESCRIPTION
    Converts a UUID string to hexadecimal format without dashes.
.PARAMETER Uuid
    The UUID string to convert (e.g., "550e8400-e29b-41d4-a716-446655440000").
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-UuidToHex
    
    Converts UUID to hex format: "550E8400E29B41D4A716446655440000"
.OUTPUTS
    System.String
    Returns the UUID in hexadecimal format without dashes.
#>
Set-Item -Path Function:Global:ConvertFrom-UuidToHex -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Uuid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-UuidToHex @PSBoundParameters
} -Force
Set-Alias -Name uuid-to-hex -Value ConvertFrom-UuidToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to UUID
<#
.SYNOPSIS
    Converts a hexadecimal string to UUID format.
.DESCRIPTION
    Converts a 32-character hexadecimal string to standard UUID format with dashes.
.PARAMETER Hex
    The hexadecimal string to convert (32 characters, with or without dashes).
.EXAMPLE
    "550E8400E29B41D4A716446655440000" | ConvertTo-UuidFromHex
    
    Converts hex to UUID format: "550e8400-e29b-41d4-a716-446655440000"
.OUTPUTS
    System.String
    Returns the UUID in standard format with dashes.
#>
Set-Item -Path Function:Global:ConvertTo-UuidFromHex -Value {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Hex
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-UuidFromHex @PSBoundParameters
} -Force
Set-Alias -Name hex-to-uuid -Value ConvertTo-UuidFromHex -Scope Global -ErrorAction SilentlyContinue

# Convert UUID to Base64
<#
.SYNOPSIS
    Converts a UUID to Base64 format.
.DESCRIPTION
    Converts a UUID string to Base64 encoded format.
.PARAMETER Uuid
    The UUID string to convert.
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-UuidToBase64
    
    Converts UUID to Base64 format.
.OUTPUTS
    System.String
    Returns the UUID in Base64 format.
#>
Set-Item -Path Function:Global:ConvertFrom-UuidToBase64 -Value {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Uuid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-UuidToBase64 @PSBoundParameters
} -Force
Set-Alias -Name uuid-to-base64 -Value ConvertFrom-UuidToBase64 -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to UUID
<#
.SYNOPSIS
    Converts a Base64 string to UUID format.
.DESCRIPTION
    Converts a Base64 encoded string to standard UUID format.
.PARAMETER Base64
    The Base64 string to convert.
.EXAMPLE
    "VQ6EAOKbQdSnFkRmVVQAAA==" | ConvertTo-UuidFromBase64
    
    Converts Base64 to UUID format.
.OUTPUTS
    System.String
    Returns the UUID in standard format with dashes.
#>
Set-Item -Path Function:Global:ConvertTo-UuidFromBase64 -Value {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Base64
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-UuidFromBase64 @PSBoundParameters
} -Force
Set-Alias -Name base64-to-uuid -Value ConvertTo-UuidFromBase64 -Scope Global -ErrorAction SilentlyContinue

# Convert UUID to Base32
<#
.SYNOPSIS
    Converts a UUID to Base32 format.
.DESCRIPTION
    Converts a UUID string to Base32 encoded format.
.PARAMETER Uuid
    The UUID string to convert.
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-UuidToBase32
    
    Converts UUID to Base32 format.
.OUTPUTS
    System.String
    Returns the UUID in Base32 format.
#>
Set-Item -Path Function:Global:ConvertFrom-UuidToBase32 -Value {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Uuid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-UuidToBase32 @PSBoundParameters
} -Force
Set-Alias -Name uuid-to-base32 -Value ConvertFrom-UuidToBase32 -Scope Global -ErrorAction SilentlyContinue

# Convert Base32 to UUID
<#
.SYNOPSIS
    Converts a Base32 string to UUID format.
.DESCRIPTION
    Converts a Base32 encoded string to standard UUID format.
.PARAMETER Base32
    The Base32 string to convert.
.EXAMPLE
    "K5VQK4VQK4VQK4VQK4VQK4VQ" | ConvertTo-UuidFromBase32
    
    Converts Base32 to UUID format.
.OUTPUTS
    System.String
    Returns the UUID in standard format with dashes.
#>
Set-Item -Path Function:Global:ConvertTo-UuidFromBase32 -Value {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Base32
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-UuidFromBase32 @PSBoundParameters
} -Force
Set-Alias -Name base32-to-uuid -Value ConvertTo-UuidFromBase32 -Scope Global -ErrorAction SilentlyContinue

# Generate new UUID
<#
.SYNOPSIS
    Generates a new UUID (GUID).
.DESCRIPTION
    Generates a new UUID (Universally Unique Identifier) using .NET Guid.NewGuid().
    Can return the UUID in various formats.
.PARAMETER AsHex
    Return the UUID as hexadecimal string without dashes.
.PARAMETER AsBase64
    Return the UUID as Base64 encoded string.
.PARAMETER AsBase32
    Return the UUID as Base32 encoded string.
.EXAMPLE
    New-Uuid
    
    Generates a new UUID in standard format.
.EXAMPLE
    New-Uuid -AsHex
    
    Generates a new UUID in hexadecimal format.
.OUTPUTS
    System.String
    Returns a new UUID in the specified format.
#>
Set-Item -Path Function:Global:New-Uuid -Value {
    param(
        [switch]$AsHex,
        [switch]$AsBase64,
        [switch]$AsBase32
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _New-Uuid @PSBoundParameters
} -Force
Set-Alias -Name new-uuid -Value New-Uuid -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name uuid -Value New-Uuid -Scope Global -ErrorAction SilentlyContinue

