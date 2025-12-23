# ===============================================
# QR Code conversion utilities
# QR Code ↔ Text, JSON, Image
# ===============================================

<#
.SYNOPSIS
    Initializes QR Code conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for QR Code format conversions.
    Supports generating QR codes from text/data and decoding QR codes from images.
    This function is called automatically by Ensure-FileConversion-Specialized.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and qrcode package for generation.
    QR code decoding may require additional image processing libraries.
#>
function Initialize-FileConversion-SpecializedQrCode {
    # Ensure dev-tools QR code functions are available
    if (-not $global:DevToolsInitialized) {
        # Try to ensure dev tools are loaded
        if (Get-Command Ensure-DevTools -ErrorAction SilentlyContinue) {
            Ensure-DevTools | Out-Null
        }
    }

    # Text/Data to QR Code image
    Set-Item -Path Function:Global:_ConvertTo-QrCodeFromText -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(txt|text|json)$', '.png'
            }
            
            $data = Get-Content -LiteralPath $InputPath -Raw
            $data = $data.Trim()
            
            # Use existing QR code generation function if available
            if (Get-Command _New-QrCode -ErrorAction SilentlyContinue) {
                _New-QrCode -Data $data -OutputPath $OutputPath -Size 200
            }
            elseif (Get-Command New-QrCode -ErrorAction SilentlyContinue) {
                New-QrCode -Data $data -OutputPath $OutputPath -Size 200
            }
            else {
                throw "QR code generation function not available. Ensure dev-tools are loaded."
            }
        }
        catch {
            Write-Error "Failed to convert text to QR code: $_"
            throw
        }
    } -Force

    # JSON to QR Code image
    Set-Item -Path Function:Global:_ConvertTo-QrCodeFromJson -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.json$', '.png'
            }
            
            $jsonContent = Get-Content -LiteralPath $InputPath -Raw
            $jsonObj = $jsonContent | ConvertFrom-Json
            $jsonString = $jsonObj | ConvertTo-Json -Compress
            
            # Use existing QR code generation function if available
            if (Get-Command _New-QrCode -ErrorAction SilentlyContinue) {
                _New-QrCode -Data $jsonString -OutputPath $OutputPath -Size 200
            }
            elseif (Get-Command New-QrCode -ErrorAction SilentlyContinue) {
                New-QrCode -Data $jsonString -OutputPath $OutputPath -Size 200
            }
            else {
                throw "QR code generation function not available. Ensure dev-tools are loaded."
            }
        }
        catch {
            Write-Error "Failed to convert JSON to QR code: $_"
            throw
        }
    } -Force

    # QR Code image to text (basic - note: full decoding requires image processing)
    Set-Item -Path Function:Global:_ConvertFrom-QrCodeToText -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $InputPath) {
                throw "InputPath parameter is required"
            }
            if ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and -not (Test-Path -LiteralPath $InputPath)) {
                throw "Input file not found: $InputPath"
            }
            if (-not $OutputPath) {
                $OutputPath = $InputPath -replace '\.(png|jpg|jpeg|gif|bmp)$', '.txt'
            }
            
            # Note: Full QR code decoding from images requires image processing libraries
            # This is a placeholder that would need qrcode-reader or similar library
            # For now, we'll indicate that decoding requires additional tools
            throw "QR code decoding from images requires additional image processing libraries. Use external tools like zbar or qrcode-reader npm package."
        }
        catch {
            Write-Error "Failed to decode QR code: $_"
            throw
        }
    } -Force
}

# Convert text to QR Code
<#
.SYNOPSIS
    Converts text file to QR Code image.
.DESCRIPTION
    Reads text from a file and generates a QR code image containing that text.
    Requires Node.js and qrcode package.
.PARAMETER InputPath
    The path to the text file (.txt or .text extension).
.PARAMETER OutputPath
    The path for the output QR code image file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertTo-QrCodeFromText -InputPath "data.txt"
    
    Converts data.txt to data.png QR code.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-QrCodeFromText {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertTo-QrCodeFromText -ErrorAction SilentlyContinue) {
            _ConvertTo-QrCodeFromText @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-QrCodeFromText not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert text to QR code: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name text-to-qrcode -Value ConvertTo-QrCodeFromText -ErrorAction SilentlyContinue

# Convert JSON to QR Code
<#
.SYNOPSIS
    Converts JSON file to QR Code image.
.DESCRIPTION
    Reads JSON from a file and generates a QR code image containing the JSON data.
    Requires Node.js and qrcode package.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output QR code image file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertTo-QrCodeFromJson -InputPath "data.json"
    
    Converts data.json to data.png QR code.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-QrCodeFromJson {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertTo-QrCodeFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-QrCodeFromJson @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-QrCodeFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to QR code: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-qrcode -Value ConvertTo-QrCodeFromJson -ErrorAction SilentlyContinue

# Convert QR Code to text
<#
.SYNOPSIS
    Converts QR Code image to text.
.DESCRIPTION
    Decodes a QR code image and extracts the text data.
    Note: Full decoding requires additional image processing libraries (qrcode-reader, zbar, etc.).
.PARAMETER InputPath
    The path to the QR code image file (.png, .jpg, .jpeg, .gif, .bmp).
.PARAMETER OutputPath
    The path for the output text file. If not specified, uses input path with .txt extension.
.EXAMPLE
    ConvertFrom-QrCodeToText -InputPath "qrcode.png"
    
    Decodes qrcode.png to qrcode.txt.
.OUTPUTS
    None. Creates output file at specified or default path.
.NOTES
    Full QR code decoding requires additional libraries. This function currently indicates the requirement.
#>
function ConvertFrom-QrCodeToText {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertFrom-QrCodeToText -ErrorAction SilentlyContinue) {
            _ConvertFrom-QrCodeToText @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-QrCodeToText not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to decode QR code: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name qrcode-to-text -Value ConvertFrom-QrCodeToText -ErrorAction SilentlyContinue

