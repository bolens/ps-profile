# ===============================================
# Morse Code encoding conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Morse Code encoding conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Morse Code encoding format.
    Morse Code uses dots (.) and dashes (-) to represent letters, numbers, and punctuation.
    Supports bidirectional conversions between Morse Code and ASCII text.
    This function is called automatically by Initialize-FileConversion-CoreEncoding.
.NOTES
    This is an internal initialization function and should not be called directly.
    Uses International Morse Code standard.
    Words are separated by spaces, letters within words are separated by single spaces.
#>
function Initialize-FileConversion-CoreEncodingMorse {
    # Morse Code mapping (International Morse Code)
    $script:MorseCodeMap = @{
        'A' = '.-'; 'B' = '-...'; 'C' = '-.-.'; 'D' = '-..'; 'E' = '.'; 'F' = '..-.';
        'G' = '--.'; 'H' = '....'; 'I' = '..'; 'J' = '.---'; 'K' = '-.-'; 'L' = '.-..';
        'M' = '--'; 'N' = '-.'; 'O' = '---'; 'P' = '.--.'; 'Q' = '--.-'; 'R' = '.-.';
        'S' = '...'; 'T' = '-'; 'U' = '..-'; 'V' = '...-'; 'W' = '.--'; 'X' = '-..-';
        'Y' = '-.--'; 'Z' = '--..';
        '0' = '-----'; '1' = '.----'; '2' = '..---'; '3' = '...--'; '4' = '....-'; '5' = '.....';
        '6' = '-....'; '7' = '--...'; '8' = '---..'; '9' = '----.';
        '.' = '.-.-.-'; ',' = '--..--'; '?' = '..--..'; "'" = '.----.'; '!' = '-.-.--';
        '/' = '-..-.'; '(' = '-.--.'; ')' = '-.--.-'; '&' = '.-...'; ':' = '---...';
        ';' = '-.-.-.'; '=' = '-...-'; '+' = '.-.-.'; '-' = '-....-'; '_' = '..--.-';
        '"' = '.-..-.'; '$' = '...-..-'; '@' = '.--.-.'
    }

    # Reverse mapping (Morse Code to character)
    $script:MorseCodeReverse = @{}
    foreach ($key in $script:MorseCodeMap.Keys) {
        $script:MorseCodeReverse[$script:MorseCodeMap[$key]] = $key
    }

    # Helper function to encode text to Morse Code
    Set-Item -Path Function:Global:_Encode-Morse -Value {
        param([string]$Text)
        if ([string]::IsNullOrEmpty($Text)) {
            return ''
        }
        $result = ''
        # Convert to uppercase and ensure it's a string
        $upperText = [string]$Text.ToUpper().Trim()
        if ([string]::IsNullOrEmpty($upperText)) {
            return ''
        }
        # Split by whitespace, filtering out empty entries
        $splitWords = $upperText -split '\s+'
        $words = @($splitWords | Where-Object { -not [string]::IsNullOrEmpty($_) })
        if ($words.Count -eq 0) {
            return ''
        }
        for ($i = 0; $i -lt $words.Count; $i++) {
            $word = [string]$words[$i]
            if ([string]::IsNullOrEmpty($word)) {
                continue
            }
            # Process each character in the word
            $wordResult = ''
            $wordLen = $word.Length
            for ($j = 0; $j -lt $wordLen; $j++) {
                $char = $word.Substring($j, 1)
                if ($script:MorseCodeMap.ContainsKey($char)) {
                    if ($wordResult.Length -gt 0) {
                        $wordResult += ' '
                    }
                    $wordResult += $script:MorseCodeMap[$char]
                }
            }
            if ($wordResult.Length -gt 0) {
                if ($result.Length -gt 0) {
                    $result += '  '
                }
                $result += $wordResult
            }
        }
        return $result
    } -Force

    # Helper function to decode Morse Code to text
    Set-Item -Path Function:Global:_Decode-Morse -Value {
        param([string]$MorseCode)
        if ([string]::IsNullOrWhiteSpace($MorseCode)) {
            return ''
        }
        # Normalize: replace multiple spaces with double space (word separator)
        $morse = $MorseCode -replace '\s{3,}', '  ' -replace '\t+', '  '
        # Split by double spaces (words)
        $words = $morse -split '\s{2,}'
        $result = ''
        for ($i = 0; $i -lt $words.Length; $i++) {
            $word = $words[$i].Trim()
            if ([string]::IsNullOrEmpty($word)) {
                continue
            }
            # Split word by single spaces (letters)
            $letters = $word -split '\s+'
            foreach ($letter in $letters) {
                $letter = $letter.Trim()
                if ([string]::IsNullOrEmpty($letter)) {
                    continue
                }
                if ($script:MorseCodeReverse.ContainsKey($letter)) {
                    $result += $script:MorseCodeReverse[$letter]
                }
                else {
                    # Unknown Morse code sequence - keep as is or skip
                    # For now, we'll skip invalid sequences
                }
            }
            # Add space between words (but not after last word)
            if ($i -lt $words.Length - 1) {
                $result += ' '
            }
        }
        return $result
    } -Force

    # ASCII to Morse Code
    Set-Item -Path Function:Global:_ConvertFrom-AsciiToMorse -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrEmpty($InputObject)) {
                return ''
            }
            try {
                return _Encode-Morse -Text $InputObject
            }
            catch {
                throw "Failed to convert ASCII to Morse Code: $_"
            }
        }
    } -Force

    # Morse Code to ASCII
    Set-Item -Path Function:Global:_ConvertFrom-MorseToAscii -Value {
        param(
            [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
            [string]$InputObject
        )
        process {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return ''
            }
            try {
                return _Decode-Morse -MorseCode $InputObject
            }
            catch {
                throw "Failed to convert Morse Code to ASCII: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert ASCII to Morse Code
<#
.SYNOPSIS
    Converts ASCII text to Morse Code encoding.
.DESCRIPTION
    Encodes ASCII text to International Morse Code format.
    Uses dots (.) and dashes (-) to represent characters.
    Words are separated by double spaces, letters within words by single spaces.
.PARAMETER InputObject
    The text string to encode.
.EXAMPLE
    "HELLO WORLD" | ConvertFrom-AsciiToMorse
    
    Converts text to Morse Code format.
.EXAMPLE
    "SOS" | ConvertFrom-AsciiToMorse
    
    Returns "... --- ..."
.OUTPUTS
    System.String
    Returns the Morse Code encoded string.
#>
function ConvertFrom-AsciiToMorse {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-AsciiToMorse @PSBoundParameters
}
Set-Alias -Name ascii-to-morse -Value ConvertFrom-AsciiToMorse -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name morse -Value ConvertFrom-AsciiToMorse -Scope Global -ErrorAction SilentlyContinue

# Convert Morse Code to ASCII
<#
.SYNOPSIS
    Converts Morse Code encoding to ASCII text.
.DESCRIPTION
    Decodes Morse Code encoded string back to ASCII text.
    Supports International Morse Code standard.
.PARAMETER InputObject
    The Morse Code encoded string to decode.
.EXAMPLE
    ".... . .-.. .-.. ---  .-- --- .-. .-.. -.." | ConvertFrom-MorseToAscii
    
    Converts Morse Code to text.
.EXAMPLE
    "... --- ..." | ConvertFrom-MorseToAscii
    
    Returns "SOS"
.OUTPUTS
    System.String
    Returns the decoded ASCII text.
#>
function ConvertFrom-MorseToAscii {
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputObject
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-MorseToAscii @PSBoundParameters
}
Set-Alias -Name morse-to-ascii -Value ConvertFrom-MorseToAscii -Scope Global -ErrorAction SilentlyContinue

