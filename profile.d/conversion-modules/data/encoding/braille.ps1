# ===============================================
# Braille encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Braille encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Braille encoding format.
    Braille uses Unicode Braille patterns (U+2800-U+28FF) to represent characters.
    Supports bidirectional conversions between Braille and ASCII text.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Uses Unicode Braille patterns for encoding.
    Maps ASCII characters to their corresponding Braille Unicode characters.
#>
function Initialize-FileConversion-CoreEncodingBraille {
    # Braille mapping: ASCII to Braille Unicode (U+2800-U+28FF)
    # Braille patterns are 6-dot patterns represented as Unicode characters
    # U+2800 is blank, U+2801-U+283F are various dot combinations
    $script:BrailleMap = @{
        # Letters (a-z)
        'A' = [char]0x2801; 'B' = [char]0x2803; 'C' = [char]0x2809; 'D' = [char]0x2819;
        'E' = [char]0x2811; 'F' = [char]0x280B; 'G' = [char]0x281B; 'H' = [char]0x2813;
        'I' = [char]0x280A; 'J' = [char]0x281A; 'K' = [char]0x2805; 'L' = [char]0x2807;
        'M' = [char]0x280D; 'N' = [char]0x281D; 'O' = [char]0x2815; 'P' = [char]0x280F;
        'Q' = [char]0x281F; 'R' = [char]0x2817; 'S' = [char]0x280E; 'T' = [char]0x281E;
        'U' = [char]0x2825; 'V' = [char]0x2827; 'W' = [char]0x283A; 'X' = [char]0x282D;
        'Y' = [char]0x283D; 'Z' = [char]0x2835;
        # Numbers (prefixed with number sign U+283C)
        '0' = [char]0x281A; '1' = [char]0x2801; '2' = [char]0x2803; '3' = [char]0x2809;
        '4' = [char]0x2819; '5' = [char]0x2811; '6' = [char]0x280B; '7' = [char]0x281B;
        '8' = [char]0x2813; '9' = [char]0x280A;
        # Punctuation
        '.' = [char]0x2832; ',' = [char]0x2802; '?' = [char]0x2826; '!' = [char]0x2816;
        ';' = [char]0x2806; ':' = [char]0x2812; '-' = [char]0x2824; '(' = [char]0x2836;
        ')' = [char]0x2836; '/' = [char]0x280C; '*' = [char]0x2814; '"' = [char]0x2826;
        "'" = [char]0x2804; ' ' = [char]0x2800  # Space
    }

    # Reverse mapping: Braille Unicode to ASCII
    $script:BrailleReverse = @{}
    foreach ($key in $script:BrailleMap.Keys) {
        $brailleChar = $script:BrailleMap[$key]
        $script:BrailleReverse[[int]$brailleChar] = $key
    }

    # Number sign for Braille numbers
    $script:BrailleNumberSign = [char]0x283C

    # Helper function to encode text to Braille
    Set-Item -Path Function:Global:_Encode-Braille -Value {
        param([string]$Text)
        if ([string]::IsNullOrEmpty($Text)) {
            return ''
        }
        $result = ''
        $upperText = $Text.ToUpper()
        $i = 0
        while ($i -lt $upperText.Length) {
            $char = $upperText[$i]
            # Check if it's a digit
            if ($char -ge '0' -and $char -le '9') {
                # Add number sign before first digit in a sequence
                if ($i -eq 0 -or ($i -gt 0 -and ($upperText[$i - 1] -lt '0' -or $upperText[$i - 1] -gt '9'))) {
                    $result += $script:BrailleNumberSign
                }
                if ($script:BrailleMap.ContainsKey($char)) {
                    $result += $script:BrailleMap[$char]
                }
            }
            elseif ($script:BrailleMap.ContainsKey($char)) {
                $result += $script:BrailleMap[$char]
            }
            else {
                # Unknown character - use space
                $result += [char]0x2800
            }
            $i++
        }
        return $result
    } -Force

    # Helper function to decode Braille to text
    Set-Item -Path Function:Global:_Decode-Braille -Value {
        param([string]$BrailleText)
        if ([string]::IsNullOrWhiteSpace($BrailleText)) {
            return ''
        }
        $result = ''
        $inNumber = $false
        $i = 0
        while ($i -lt $BrailleText.Length) {
            $brailleChar = $BrailleText[$i]
            $brailleCode = [int]$brailleChar
            
            # Check for number sign
            if ($brailleCode -eq [int]$script:BrailleNumberSign) {
                $inNumber = $true
                $i++
                continue
            }
            
            # Decode Braille character
            if ($script:BrailleReverse.ContainsKey($brailleCode)) {
                $asciiChar = $script:BrailleReverse[$brailleCode]
                # If we're in a number sequence and this is a letter pattern, convert to digit
                if ($inNumber -and $asciiChar -ge 'A' -and $asciiChar -le 'J') {
                    # Braille letters A-J represent digits 1-0
                    $digit = if ($asciiChar -eq 'J') { '0' } else { ([int][char]$asciiChar - [int][char]'A' + 1).ToString() }
                    $result += $digit
                }
                else {
                    $result += $asciiChar
                    $inNumber = $false
                }
            }
            elseif ($brailleCode -eq 0x2800) {
                # Blank Braille cell (space)
                $result += ' '
                $inNumber = $false
            }
            else {
                # Unknown Braille pattern - skip or use placeholder
                $inNumber = $false
            }
            $i++
        }
        return $result
    } -Force

    # ASCII to Braille
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToBraille -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                return _Encode-Braille -Text $InputObject
            }
            catch {
                throw "Failed to convert ASCII to Braille: $_"
            }
        }
    } -Force

    # Braille to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-BrailleToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                return _Decode-Braille -BrailleText $InputObject
            }
            catch {
                throw "Failed to convert Braille to ASCII: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Braille
<#
.SYNOPSIS
    Converts ASCII text to Braille encoding.
.DESCRIPTION
    Encodes ASCII text to Unicode Braille patterns.
    Uses standard 6-dot Braille patterns (U+2800-U+28FF).
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "HELLO" | ConvertFrom-AsciiToBraille
    
    Converts text to Braille Unicode format.
.EXAMPLE
    "123" | ConvertFrom-AsciiToBraille
    
    Converts numbers to Braille (with number sign prefix).
.OUTPUTS
    System.String
    Returns the Braille encoded string (Unicode characters).
#>
function ConvertFrom-AsciiToBraille {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToBraille @PSBoundParameters
}
Set-Alias -Name ascii-to-braille -Value ConvertFrom-AsciiToBraille -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name braille -Value ConvertFrom-AsciiToBraille -Scope Global -ErrorAction SilentlyContinue

# Convert Braille to ASCII
<#
.SYNOPSIS
    Converts Braille encoding to ASCII text.
.DESCRIPTION
    Decodes Unicode Braille patterns back to ASCII text.
    Supports standard 6-dot Braille patterns.
.PARAMETER InputObject
    The Braille encoded string (Unicode characters).
.EXAMPLE
    "⠓⠑⠇⠇⠕" | ConvertFrom-BrailleToAscii
    
    Converts Braille to text.
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-BrailleToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-BrailleToAscii @PSBoundParameters
}
Set-Alias -Name braille-to-ascii -Value ConvertFrom-BrailleToAscii -Scope Global -ErrorAction SilentlyContinue

