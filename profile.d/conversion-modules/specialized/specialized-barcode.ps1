# ===============================================
# Barcode conversion utilities
# Barcode ↔ Text, JSON, Image
# ===============================================

<#
.SYNOPSIS
    Initializes Barcode conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Barcode format conversions.
    Supports generating barcodes from text/data and decoding barcodes from images.
    This function is called automatically by Ensure-FileConversion-Specialized.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and jsbarcode package for generation.
    Barcode decoding may require additional image processing libraries.
#>
function Initialize-FileConversion-SpecializedBarcode {
    # Text/Data to Barcode image
    Set-Item -Path Function:Global:_ConvertTo-BarcodeFromText -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [ValidateSet('CODE128', 'CODE39', 'EAN13', 'EAN8', 'UPC', 'ITF14', 'MSI', 'pharmacode', 'codabar')]
            [string]$Format = 'CODE128'
        )
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
            
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use barcode generation."
            }
            
            if ($Data) {
                $data = $Data
            }
            elseif ($InputPath) {
                $data = Get-Content -LiteralPath $InputPath -Raw
                $data = $data.Trim()
            }
            else {
                throw "Either InputPath or Data parameter must be provided"
            }
            
            $nodeScript = @"
try {
    const JsBarcode = require('jsbarcode');
    const { createCanvas } = require('canvas');
    const fs = require('fs');
    const path = require('path');
    
    const data = process.argv[1];
    const outputPath = process.argv[2];
    const format = process.argv[3] || 'CODE128';
    
    const canvas = createCanvas(200, 100);
    JsBarcode(canvas, data, {
        format: format,
        width: 2,
        height: 100,
        displayValue: true
    });
    
    const buffer = canvas.toBuffer('image/png');
    fs.writeFileSync(outputPath, buffer);
    console.log('Barcode generated successfully');
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: jsbarcode or canvas package is not installed. Install with: npm install -g jsbarcode canvas');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "barcode-gen-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = & node $tempScript $data $OutputPath $Format 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -ne 0) {
                    $errorMessage = if ($result) { $result -join "`n" } else { "Unknown error" }
                    throw "Node.js script failed with exit code $exitCode : $errorMessage"
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert text to barcode: $_"
            throw
        }
    } -Force

    # JSON to Barcode image
    Set-Item -Path Function:Global:_ConvertTo-BarcodeFromJson -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [ValidateSet('CODE128', 'CODE39', 'EAN13', 'EAN8', 'UPC', 'ITF14', 'MSI', 'pharmacode', 'codabar')]
            [string]$Format = 'CODE128'
        )
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
            
            # Create temporary text file with JSON string
            $tempTextFile = Join-Path $env:TEMP "barcode-json-$(Get-Random).txt"
            try {
                Set-Content -LiteralPath $tempTextFile -Value $jsonString -Encoding UTF8 -NoNewline
                _ConvertTo-BarcodeFromText -InputPath $tempTextFile -OutputPath $OutputPath -Format $Format
            }
            finally {
                Remove-Item -LiteralPath $tempTextFile -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to convert JSON to barcode: $_"
            throw
        }
    } -Force

    # Barcode image to text (basic - note: full decoding requires image processing)
    Set-Item -Path Function:Global:_ConvertFrom-BarcodeToText -Value {
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
            
            # Note: Full barcode decoding from images requires image processing libraries
            # This is a placeholder that would need barcode-reader or similar library
            # For now, we'll indicate that decoding requires additional tools
            throw "Barcode decoding from images requires additional image processing libraries. Use external tools like zbar or barcode-reader npm package."
        }
        catch {
            Write-Error "Failed to decode barcode: $_"
            throw
        }
    } -Force
}

# Convert text to Barcode
<#
.SYNOPSIS
    Converts text file to Barcode image.
.DESCRIPTION
    Reads text from a file and generates a barcode image containing that text.
    Requires Node.js, jsbarcode, and canvas packages.
.PARAMETER InputPath
    The path to the text file (.txt or .text extension).
.PARAMETER OutputPath
    The path for the output barcode image file. If not specified, uses input path with .png extension.
.PARAMETER Format
    The barcode format to use. Valid values: CODE128, CODE39, EAN13, EAN8, UPC, ITF14, MSI, pharmacode, codabar.
    Default is CODE128.
.EXAMPLE
    ConvertTo-BarcodeFromText -InputPath "data.txt" -Format CODE128
    
    Converts data.txt to data.png barcode.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-BarcodeFromText {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet('CODE128', 'CODE39', 'EAN13', 'EAN8', 'UPC', 'ITF14', 'MSI', 'pharmacode', 'codabar')]
        [string]$Format = 'CODE128'
    )
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertTo-BarcodeFromText -ErrorAction SilentlyContinue) {
            _ConvertTo-BarcodeFromText -InputPath $InputPath -OutputPath $OutputPath -Format $Format
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-BarcodeFromText not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert text to barcode: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name text-to-barcode -Value ConvertTo-BarcodeFromText -ErrorAction SilentlyContinue

# Convert JSON to Barcode
<#
.SYNOPSIS
    Converts JSON file to Barcode image.
.DESCRIPTION
    Reads JSON from a file and generates a barcode image containing the JSON data.
    Requires Node.js, jsbarcode, and canvas packages.
.PARAMETER InputPath
    The path to the JSON file.
.PARAMETER OutputPath
    The path for the output barcode image file. If not specified, uses input path with .png extension.
.PARAMETER Format
    The barcode format to use. Valid values: CODE128, CODE39, EAN13, EAN8, UPC, ITF14, MSI, pharmacode, codabar.
    Default is CODE128.
.EXAMPLE
    ConvertTo-BarcodeFromJson -InputPath "data.json" -Format CODE128
    
    Converts data.json to data.png barcode.
.OUTPUTS
    None. Creates output file at specified or default path.
#>
function ConvertTo-BarcodeFromJson {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet('CODE128', 'CODE39', 'EAN13', 'EAN8', 'UPC', 'ITF14', 'MSI', 'pharmacode', 'codabar')]
        [string]$Format = 'CODE128'
    )
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertTo-BarcodeFromJson -ErrorAction SilentlyContinue) {
            _ConvertTo-BarcodeFromJson -InputPath $InputPath -OutputPath $OutputPath -Format $Format
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-BarcodeFromJson not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JSON to barcode: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name json-to-barcode -Value ConvertTo-BarcodeFromJson -ErrorAction SilentlyContinue

# Convert Barcode to text
<#
.SYNOPSIS
    Converts Barcode image to text.
.DESCRIPTION
    Decodes a barcode image and extracts the text data.
    Note: Full decoding requires additional image processing libraries (barcode-reader, zbar, etc.).
.PARAMETER InputPath
    The path to the barcode image file (.png, .jpg, .jpeg, .gif, .bmp).
.PARAMETER OutputPath
    The path for the output text file. If not specified, uses input path with .txt extension.
.EXAMPLE
    ConvertFrom-BarcodeToText -InputPath "barcode.png"
    
    Decodes barcode.png to barcode.txt.
.OUTPUTS
    None. Creates output file at specified or default path.
.NOTES
    Full barcode decoding requires additional libraries. This function currently indicates the requirement.
#>
function ConvertFrom-BarcodeToText {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionSpecializedInitialized) { Ensure-FileConversion-Specialized }
    try {
        if (Get-Command _ConvertFrom-BarcodeToText -ErrorAction SilentlyContinue) {
            _ConvertFrom-BarcodeToText @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-BarcodeToText not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to decode barcode: $_" -ErrorAction SilentlyContinue
    }
}
Set-Alias -Name barcode-to-text -Value ConvertFrom-BarcodeToText -ErrorAction SilentlyContinue

