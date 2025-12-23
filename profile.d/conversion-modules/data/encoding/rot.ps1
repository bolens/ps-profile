# ===============================================
# ROT13/ROT47 cipher encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes ROT13/ROT47 cipher encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ROT13 and ROT47 cipher encoding formats.
    ROT13 rotates letters by 13 positions (A-Z, a-z).
    ROT47 rotates all printable ASCII characters (33-126) by 47 positions.
    Supports bidirectional conversions (encoding and decoding are the same operation).
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    ROT13 and ROT47 are self-inverse ciphers (applying twice returns original text).
#>
function Initialize-FileConversion-CoreEncodingRot {
    # ROT13: Rotate A-Z and a-z by 13 positions
    Set-Item -Path Function:Global:_Encode-Rot13 -Value {
        param([string]$Text)
        if ([string]::IsNullOrEmpty($Text)) {
            return ''
        }
        $result = ''
        foreach ($char in $Text.ToCharArray()) {
            if ($char -ge 'A' -and $char -le 'Z') {
                $rotated = [char]((([int][char]$char - [int][char]'A' + 13) % 26) + [int][char]'A')
                $result += $rotated
            }
            elseif ($char -ge 'a' -and $char -le 'z') {
                $rotated = [char]((([int][char]$char - [int][char]'a' + 13) % 26) + [int][char]'a')
                $result += $rotated
            }
            else {
                $result += $char
            }
        }
        return $result
    } -Force

    # ROT47: Rotate all printable ASCII (33-126) by 47 positions
    Set-Item -Path Function:Global:_Encode-Rot47 -Value {
        param([string]$Text)
        if ([string]::IsNullOrEmpty($Text)) {
            return ''
        }
        $result = ''
        foreach ($char in $Text.ToCharArray()) {
            $code = [int][char]$char
            if ($code -ge 33 -and $code -le 126) {
                $rotated = $code + 47
                if ($rotated -gt 126) {
                    $rotated = $rotated - 94  # Wrap around (126 - 33 + 1 = 94)
                }
                $result += [char]$rotated
            }
            else {
                $result += $char
            }
        }
        return $result
    } -Force

    # ASCII to ROT13
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToRot13 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                return _Encode-Rot13 -Text $InputObject
            }
            catch {
                throw "Failed to convert ASCII to ROT13: $_"
            }
        }
    } -Force

    # ROT13 to ASCII (same as encoding, since ROT13 is self-inverse)
    Set-Item -Path Function:Global:_ConvertFrom-Rot13ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                return _Encode-Rot13 -Text $InputObject
            }
            catch {
                throw "Failed to convert ROT13 to ASCII: $_"
            }
        }
    } -Force

    # ASCII to ROT47
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToRot47 -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                return _Encode-Rot47 -Text $InputObject
            }
            catch {
                throw "Failed to convert ASCII to ROT47: $_"
            }
        }
    } -Force

    # ROT47 to ASCII (same as encoding, since ROT47 is self-inverse)
    Set-Item -Path Function:Global:_ConvertFrom-Rot47ToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                return _Encode-Rot47 -Text $InputObject
            }
            catch {
                throw "Failed to convert ROT47 to ASCII: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to ROT13
<#
.SYNOPSIS
    Converts ASCII text to ROT13 cipher encoding.
.DESCRIPTION
    Encodes ASCII text using ROT13 cipher (rotates letters by 13 positions).
    ROT13 is a self-inverse cipher - applying it twice returns the original text.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World" | ConvertFrom-AsciiToRot13
    
    Converts text to ROT13 format.
.EXAMPLE
    "Uryyb Jbeyq" | ConvertFrom-Rot13ToAscii
    
    Decodes ROT13 back to original text.
.OUTPUTS
    System.String
    Returns the ROT13 encoded string.
#>
function ConvertFrom-AsciiToRot13 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToRot13 @PSBoundParameters
}
Set-Alias -Name ascii-to-rot13 -Value ConvertFrom-AsciiToRot13 -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name rot13 -Value ConvertFrom-AsciiToRot13 -Scope Global -ErrorAction SilentlyContinue

# Convert ROT13 to ASCII
<#
.SYNOPSIS
    Converts ROT13 cipher encoding to ASCII text.
.DESCRIPTION
    Decodes ROT13 encoded string back to ASCII text.
    Since ROT13 is self-inverse, this is the same as encoding.
.PARAMETER InputObject
    The ROT13 encoded string to decode.
.EXAMPLE
    "Uryyb Jbeyq" | ConvertFrom-Rot13ToAscii
    
    Converts ROT13 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Rot13ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Rot13ToAscii @PSBoundParameters
}
Set-Alias -Name rot13-to-ascii -Value ConvertFrom-Rot13ToAscii -Scope Global -ErrorAction SilentlyContinue

# Convert ASCII to ROT47
<#
.SYNOPSIS
    Converts ASCII text to ROT47 cipher encoding.
.DESCRIPTION
    Encodes ASCII text using ROT47 cipher (rotates all printable ASCII characters by 47 positions).
    ROT47 is a self-inverse cipher - applying it twice returns the original text.
    Unlike ROT13, ROT47 also encodes numbers and special characters.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "Hello World!" | ConvertFrom-AsciiToRot47
    
    Converts text to ROT47 format.
.EXAMPLE
    "w6==@ (@C=5P" | ConvertFrom-Rot47ToAscii
    
    Decodes ROT47 back to original text.
.OUTPUTS
    System.String
    Returns the ROT47 encoded string.
#>
function ConvertFrom-AsciiToRot47 {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToRot47 @PSBoundParameters
}
Set-Alias -Name ascii-to-rot47 -Value ConvertFrom-AsciiToRot47 -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name rot47 -Value ConvertFrom-AsciiToRot47 -Scope Global -ErrorAction SilentlyContinue

# Convert ROT47 to ASCII
<#
.SYNOPSIS
    Converts ROT47 cipher encoding to ASCII text.
.DESCRIPTION
    Decodes ROT47 encoded string back to ASCII text.
    Since ROT47 is self-inverse, this is the same as encoding.
.PARAMETER InputObject
    The ROT47 encoded string to decode.
.EXAMPLE
    "w6==@ (@C=5P" | ConvertFrom-Rot47ToAscii
    
    Converts ROT47 to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-Rot47ToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-Rot47ToAscii @PSBoundParameters
}
Set-Alias -Name rot47-to-ascii -Value ConvertFrom-Rot47ToAscii -Scope Global -ErrorAction SilentlyContinue

