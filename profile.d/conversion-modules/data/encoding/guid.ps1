# ===============================================
# GUID (Globally Unique Identifier) format conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes GUID format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for GUID (Globally Unique Identifier) format conversions.
    GUIDs are Windows-specific identifiers, similar to UUIDs but with Windows registry format support.
    Supports conversions between GUID formats: standard format, hex (no dashes), Base64, Base32, and registry format.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    GUID format: 8-4-4-4-12 hexadecimal digits (e.g., 550e8400-e29b-41d4-a716-446655440000)
    Windows registry format: {550e8400-e29b-41d4-a716-446655440000}
#>
function Initialize-FileConversion-CoreEncodingGuid {
    # GUID to Hex (no dashes)
    Set-Item -Path Function:Global:_ConvertFrom-GuidToHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Guid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Guid)) { return }
            try {
                # Remove braces and dashes, convert to uppercase
                $hex = $Guid -replace '[{}]', '' -replace '-', '' -replace '\s+', ''
                if ($hex.Length -ne 32) {
                    throw "Invalid GUID format: expected 32 hex characters"
                }
                if ($hex -notmatch '^[0-9A-Fa-f]{32}$') {
                    throw "Invalid GUID format: contains non-hexadecimal characters"
                }
                return $hex.ToUpper()
            }
            catch {
                throw "Failed to convert GUID to hex: $_"
            }
        }
    } -Force

    # Hex (no dashes) to GUID
    Set-Item -Path Function:Global:_ConvertTo-GuidFromHex -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Hex,
            [switch]$RegistryFormat
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Hex)) { return }
            try {
                # Remove spaces and ensure uppercase
                $hex = $Hex -replace '\s+', '' -replace '-', '' -replace '[{}]', ''
                if ($hex.Length -ne 32) {
                    throw "Invalid hex string: expected 32 hex characters"
                }
                if ($hex -notmatch '^[0-9A-Fa-f]{32}$') {
                    throw "Invalid hex string: contains non-hexadecimal characters"
                }
                # Format as GUID: 8-4-4-4-12
                $guid = "$($hex.Substring(0, 8))-$($hex.Substring(8, 4))-$($hex.Substring(12, 4))-$($hex.Substring(16, 4))-$($hex.Substring(20, 12))"
                if ($RegistryFormat) {
                    return "{$guid}"
                }
                return $guid
            }
            catch {
                throw "Failed to convert hex to GUID: $_"
            }
        }
    } -Force

    # GUID to Registry Format
    Set-Item -Path Function:Global:_ConvertFrom-GuidToRegistryFormat -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Guid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Guid)) { return }
            try {
                # Remove existing braces if present
                $guid = $Guid -replace '[{}]', ''
                # Ensure it's in standard format
                if ($guid -notmatch '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$') {
                    throw "Invalid GUID format"
                }
                return "{$guid}"
            }
            catch {
                throw "Failed to convert GUID to registry format: $_"
            }
        }
    } -Force

    # Registry Format to GUID
    Set-Item -Path Function:Global:_ConvertTo-GuidFromRegistryFormat -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$RegistryGuid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($RegistryGuid)) { return }
            try {
                # Remove braces
                $guid = $RegistryGuid -replace '[{}]', ''
                if ($guid -notmatch '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$') {
                    throw "Invalid registry GUID format"
                }
                return $guid
            }
            catch {
                throw "Failed to convert registry format to GUID: $_"
            }
        }
    } -Force

    # GUID to Base64
    Set-Item -Path Function:Global:_ConvertFrom-GuidToBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Guid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Guid)) { return }
            try {
                $hex = _ConvertFrom-GuidToHex -Guid $Guid
                $bytes = for ($i = 0; $i -lt $hex.Length; $i += 2) {
                    [Convert]::ToByte($hex.Substring($i, 2), 16)
                }
                return [Convert]::ToBase64String($bytes)
            }
            catch {
                throw "Failed to convert GUID to Base64: $_"
            }
        }
    } -Force

    # Base64 to GUID
    Set-Item -Path Function:Global:_ConvertTo-GuidFromBase64 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Base64,
            [switch]$RegistryFormat
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Base64)) { return }
            try {
                $bytes = [Convert]::FromBase64String($Base64.Trim())
                if ($bytes.Length -ne 16) {
                    throw "Invalid Base64: expected 16 bytes for GUID"
                }
                $hex = ($bytes | ForEach-Object { $_.ToString('X2') }) -join ''
                Write-Output (_ConvertTo-GuidFromHex -Hex $hex -RegistryFormat:$RegistryFormat)
            }
            catch {
                throw "Failed to convert Base64 to GUID: $_"
            }
        }
    } -Force

    # GUID to UUID (they're the same format, just different names)
    Set-Item -Path Function:Global:_ConvertFrom-GuidToUuid -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Guid
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Guid)) { return }
            try {
                # Remove braces if present
                $guid = $Guid -replace '[{}]', ''
                # Validate format
                if ($guid -notmatch '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$') {
                    throw "Invalid GUID format"
                }
                return $guid
            }
            catch {
                throw "Failed to convert GUID to UUID: $_"
            }
        }
    } -Force

    # UUID to GUID
    Set-Item -Path Function:Global:_ConvertTo-GuidFromUuid -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$Uuid,
            [switch]$RegistryFormat
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Uuid)) { return }
            try {
                # Validate format
                if ($Uuid -notmatch '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$') {
                    throw "Invalid UUID format"
                }
                if ($RegistryFormat) {
                    return "{$Uuid}"
                }
                return $Uuid
            }
            catch {
                throw "Failed to convert UUID to GUID: $_"
            }
        }
    } -Force

    # Generate new GUID
    Set-Item -Path Function:Global:_New-Guid -Value {
        param(
            [switch]$RegistryFormat,
            [switch]$AsHex,
            [switch]$AsBase64
        )
        try {
            $guid = [Guid]::NewGuid()
            $guidString = $guid.ToString()
            
            if ($AsHex) {
                _ConvertFrom-GuidToHex -Guid $guidString
            }
            elseif ($AsBase64) {
                _ConvertFrom-GuidToBase64 -Guid $guidString
            }
            elseif ($RegistryFormat) {
                return "{$guidString}"
            }
            else {
                return $guidString
            }
        }
        catch {
            throw "Failed to generate GUID: $_"
        }
    } -Force
}

# Public functions and aliases
# Convert GUID to Hex
<#
.SYNOPSIS
    Converts a GUID to hexadecimal format (no dashes).
.DESCRIPTION
    Converts a GUID string to hexadecimal format without dashes or braces.
.PARAMETER Guid
    The GUID string to convert (e.g., "550e8400-e29b-41d4-a716-446655440000" or "{550e8400-e29b-41d4-a716-446655440000}").
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToHex
    
    Converts GUID to hex format: "550E8400E29B41D4A716446655440000"
.OUTPUTS
    System.String
    Returns the GUID in hexadecimal format without dashes.
#>
Set-Item -Path Function:Global:ConvertFrom-GuidToHex -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Guid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-GuidToHex @PSBoundParameters
} -Force
Set-Alias -Name guid-to-hex -Value ConvertFrom-GuidToHex -Scope Global -ErrorAction SilentlyContinue

# Convert Hex to GUID
<#
.SYNOPSIS
    Converts a hexadecimal string to GUID format.
.DESCRIPTION
    Converts a 32-character hexadecimal string to standard GUID format with dashes.
.PARAMETER Hex
    The hexadecimal string to convert (32 characters).
.PARAMETER RegistryFormat
    Return the GUID in Windows registry format with braces.
.EXAMPLE
    "550E8400E29B41D4A716446655440000" | ConvertTo-GuidFromHex
    
    Converts hex to GUID format: "550e8400-e29b-41d4-a716-446655440000"
.EXAMPLE
    "550E8400E29B41D4A716446655440000" | ConvertTo-GuidFromHex -RegistryFormat
    
    Converts hex to GUID registry format: "{550e8400-e29b-41d4-a716-446655440000}"
.OUTPUTS
    System.String
    Returns the GUID in standard format with dashes (or registry format if specified).
#>
Set-Item -Path Function:Global:ConvertTo-GuidFromHex -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Hex,
        [switch]$RegistryFormat
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-GuidFromHex @PSBoundParameters
} -Force
Set-Alias -Name hex-to-guid -Value ConvertTo-GuidFromHex -Scope Global -ErrorAction SilentlyContinue

# Convert GUID to Registry Format
<#
.SYNOPSIS
    Converts a GUID to Windows registry format.
.DESCRIPTION
    Converts a GUID string to Windows registry format with braces.
.PARAMETER Guid
    The GUID string to convert.
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToRegistryFormat
    
    Converts GUID to registry format: "{550e8400-e29b-41d4-a716-446655440000}"
.OUTPUTS
    System.String
    Returns the GUID in Windows registry format with braces.
#>
Set-Item -Path Function:Global:ConvertFrom-GuidToRegistryFormat -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Guid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-GuidToRegistryFormat @PSBoundParameters
} -Force
Set-Alias -Name guid-to-registry -Value ConvertFrom-GuidToRegistryFormat -Scope Global -ErrorAction SilentlyContinue

# Convert Registry Format to GUID
<#
.SYNOPSIS
    Converts a Windows registry format GUID to standard format.
.DESCRIPTION
    Converts a GUID in Windows registry format (with braces) to standard format.
.PARAMETER RegistryGuid
    The registry format GUID string to convert.
.EXAMPLE
    "{550e8400-e29b-41d4-a716-446655440000}" | ConvertTo-GuidFromRegistryFormat
    
    Converts registry format to standard GUID: "550e8400-e29b-41d4-a716-446655440000"
.OUTPUTS
    System.String
    Returns the GUID in standard format without braces.
#>
Set-Item -Path Function:Global:ConvertTo-GuidFromRegistryFormat -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$RegistryGuid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-GuidFromRegistryFormat @PSBoundParameters
} -Force
Set-Alias -Name registry-to-guid -Value ConvertTo-GuidFromRegistryFormat -Scope Global -ErrorAction SilentlyContinue

# Convert GUID to Base64
<#
.SYNOPSIS
    Converts a GUID to Base64 format.
.DESCRIPTION
    Converts a GUID string to Base64 encoded format.
.PARAMETER Guid
    The GUID string to convert.
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToBase64
    
    Converts GUID to Base64 format.
.OUTPUTS
    System.String
    Returns the GUID in Base64 format.
#>
Set-Item -Path Function:Global:ConvertFrom-GuidToBase64 -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Guid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-GuidToBase64 @PSBoundParameters
} -Force
Set-Alias -Name guid-to-base64 -Value ConvertFrom-GuidToBase64 -Scope Global -ErrorAction SilentlyContinue

# Convert Base64 to GUID
<#
.SYNOPSIS
    Converts a Base64 string to GUID format.
.DESCRIPTION
    Converts a Base64 encoded string to standard GUID format.
.PARAMETER Base64
    The Base64 string to convert.
.PARAMETER RegistryFormat
    Return the GUID in Windows registry format with braces.
.EXAMPLE
    "VQ6EAOKbQdSnFkRmVVQAAA==" | ConvertTo-GuidFromBase64
    
    Converts Base64 to GUID format.
.OUTPUTS
    System.String
    Returns the GUID in standard format (or registry format if specified).
#>
Set-Item -Path Function:Global:ConvertTo-GuidFromBase64 -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Base64,
        [switch]$RegistryFormat
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-GuidFromBase64 @PSBoundParameters
} -Force
Set-Alias -Name base64-to-guid -Value ConvertTo-GuidFromBase64 -Scope Global -ErrorAction SilentlyContinue

# Convert GUID to UUID
<#
.SYNOPSIS
    Converts a GUID to UUID format.
.DESCRIPTION
    Converts a GUID string to UUID format (they're the same format, just different names).
.PARAMETER Guid
    The GUID string to convert.
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToUuid
    
    Converts GUID to UUID format (same format).
.OUTPUTS
    System.String
    Returns the GUID as a UUID string.
#>
Set-Item -Path Function:Global:ConvertFrom-GuidToUuid -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Guid
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-GuidToUuid @PSBoundParameters
} -Force
Set-Alias -Name guid-to-uuid -Value ConvertFrom-GuidToUuid -Scope Global -ErrorAction SilentlyContinue

# Convert UUID to GUID
<#
.SYNOPSIS
    Converts a UUID to GUID format.
.DESCRIPTION
    Converts a UUID string to GUID format (they're the same format, just different names).
.PARAMETER Uuid
    The UUID string to convert.
.PARAMETER RegistryFormat
    Return the GUID in Windows registry format with braces.
.EXAMPLE
    "550e8400-e29b-41d4-a716-446655440000" | ConvertTo-GuidFromUuid
    
    Converts UUID to GUID format (same format).
.OUTPUTS
    System.String
    Returns the UUID as a GUID string.
#>
Set-Item -Path Function:Global:ConvertTo-GuidFromUuid -Value {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Uuid,
        [switch]$RegistryFormat
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-GuidFromUuid @PSBoundParameters
} -Force
Set-Alias -Name uuid-to-guid -Value ConvertTo-GuidFromUuid -Scope Global -ErrorAction SilentlyContinue

# Generate new GUID
<#
.SYNOPSIS
    Generates a new GUID (Globally Unique Identifier).
.DESCRIPTION
    Generates a new GUID using .NET Guid.NewGuid().
    Can return the GUID in various formats.
.PARAMETER RegistryFormat
    Return the GUID in Windows registry format with braces.
.PARAMETER AsHex
    Return the GUID as hexadecimal string without dashes.
.PARAMETER AsBase64
    Return the GUID as Base64 encoded string.
.EXAMPLE
    New-Guid
    
    Generates a new GUID in standard format.
.EXAMPLE
    New-Guid -RegistryFormat
    
    Generates a new GUID in Windows registry format.
.EXAMPLE
    New-Guid -AsHex
    
    Generates a new GUID in hexadecimal format.
.OUTPUTS
    System.String
    Returns a new GUID in the specified format.
#>
Set-Item -Path Function:Global:New-Guid -Value {
    param(
        [switch]$RegistryFormat,
        [switch]$AsHex,
        [switch]$AsBase64
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _New-Guid @PSBoundParameters
} -Force
Set-Alias -Name new-guid -Value New-Guid -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name guid -Value New-Guid -Scope Global -ErrorAction SilentlyContinue

