# ===============================================
# QR code generation utilities - Format modules
# SVG, Terminal, and Data URI formats
# ===============================================

<#
.SYNOPSIS
    Initializes format-specific QR code generation functions.
.DESCRIPTION
    Sets up internal functions for generating QR codes in different formats (SVG, Terminal, Data URI).
    This function is called automatically by Initialize-DevTools-QrCode.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and qrcode package.
#>
function Initialize-DevTools-QrCode-Formats {
    # SVG QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeSvg -Value {
        param(
            [string]$Data,
            [string]$OutputPath,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M',
            [string]$DarkColor = '#000000',
            [string]$LightColor = '#FFFFFF',
            [int]$Margin = 4
        )
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use QR code generation."
            }
            $nodeScript = @"
try {
    const QRCode = require('qrcode');
    const fs = require('fs');
    const data = process.argv[1];
    const outputPath = process.argv[2];
    const options = JSON.parse(process.argv[3]);
    QRCode.toFile(outputPath, data, options, (err) => {
        if (err) {
            console.error('Error:', err.message);
            process.exit(1);
        }
    });
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: qrcode package is not installed. Install it with: npm install -g qrcode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $options = @{
                type                 = 'svg'
                width                = $Size
                errorCorrectionLevel = $ErrorCorrectionLevel
                color                = @{
                    dark  = $DarkColor
                    light = $LightColor
                }
                margin               = $Margin
            } | ConvertTo-Json -Compress

            $tempScript = Join-Path $env:TEMP "qrcode-svg-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $Data, $OutputPath, $options
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                Write-Host "QR code SVG generated: $OutputPath" -ForegroundColor Green
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.svg' -Context @{}
            }
            else {
                Write-Error "Failed to generate QR code SVG: $_"
            }
        }
    } -Force

    # Terminal QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeTerminal -Value {
        param(
            [string]$Data,
            [switch]$Small
        )
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use QR code generation."
            }
            $nodeScript = @"
try {
    const QRCode = require('qrcode');
    const data = process.argv[1];
    const small = process.argv[2] === 'true';
    QRCode.toString(data, { type: 'terminal', small: small }, (err, string) => {
        if (err) {
            console.error('Error:', err.message);
            process.exit(1);
        }
        console.log(string);
    });
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: qrcode package is not installed. Install it with: npm install -g qrcode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $tempScript = Join-Path $env:TEMP "qrcode-term-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $Data, $Small.IsPresent
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                if ($result) {
                    Write-Output $result
                }
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.terminal' -Context @{}
            }
            else {
                Write-Error "Failed to generate terminal QR code: $_"
            }
        }
    } -Force

    # Data URI QR Code Generator
    Set-Item -Path Function:Global:_New-QrCodeDataUri -Value {
        param(
            [string]$Data,
            [int]$Size = 200,
            [ValidateSet('L', 'M', 'Q', 'H')]
            [string]$ErrorCorrectionLevel = 'M',
            [string]$DarkColor = '#000000',
            [string]$LightColor = '#FFFFFF',
            [int]$Margin = 4
        )
        try {
            if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                throw "Node.js is not available. Install Node.js to use QR code generation."
            }
            $nodeScript = @"
try {
    const QRCode = require('qrcode');
    const data = process.argv[1];
    const options = JSON.parse(process.argv[2]);
    QRCode.toDataURL(data, options, (err, url) => {
        if (err) {
            console.error('Error:', err.message);
            process.exit(1);
        }
        console.log(url);
    });
} catch (error) {
    if (error.code === 'MODULE_NOT_FOUND') {
        console.error('Error: qrcode package is not installed. Install it with: npm install -g qrcode');
    } else {
        console.error('Error:', error.message);
    }
    process.exit(1);
}
"@
            $options = @{
                width                = $Size
                errorCorrectionLevel = $ErrorCorrectionLevel
                color                = @{
                    dark  = $DarkColor
                    light = $LightColor
                }
                margin               = $Margin
            } | ConvertTo-Json -Compress

            $tempScript = Join-Path $env:TEMP "qrcode-uri-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $Data, $options
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
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'dev-tools.format.qrcode.data-uri' -Context @{}
            }
            else {
                Write-Error "Failed to generate QR code data URI: $_"
            }
        }
    } -Force
}

# Public functions and aliases
<#
.SYNOPSIS
    Generates a QR code as an SVG image.
.DESCRIPTION
    Creates a scalable QR code SVG file from the provided data.
    Requires Node.js and qrcode package.
.PARAMETER Data
    The data to encode in the QR code.
.PARAMETER OutputPath
    The path where the QR code SVG will be saved.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.PARAMETER DarkColor
    Color of the dark modules (foreground). Default is #000000 (black).
.PARAMETER LightColor
    Color of the light modules (background). Default is #FFFFFF (white).
.PARAMETER Margin
    Margin size in modules. Default is 4.
.EXAMPLE
    New-QrCodeSvg -Data "https://example.com" -OutputPath "qrcode.svg"
    Generates a scalable SVG QR code for the URL.
#>
function New-QrCodeSvg {
    param(
        [Parameter(Mandatory)]
        [string]$Data,
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M',
        [string]$DarkColor = '#000000',
        [string]$LightColor = '#FFFFFF',
        [int]$Margin = 4
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeSvg @PSBoundParameters
}

<#
.SYNOPSIS
    Displays a QR code in the terminal.
.DESCRIPTION
    Generates and displays a QR code directly in the terminal using ASCII characters.
    Requires Node.js and qrcode package.
.PARAMETER Data
    The data to encode in the QR code.
.PARAMETER Small
    Use a smaller version of the terminal QR code.
.EXAMPLE
    New-QrCodeTerminal -Data "https://example.com"
    Displays a QR code in the terminal that can be scanned.
#>
function New-QrCodeTerminal {
    param(
        [Parameter(Mandatory)]
        [string]$Data,
        [switch]$Small
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeTerminal @PSBoundParameters
}

<#
.SYNOPSIS
    Generates a QR code as a data URI.
.DESCRIPTION
    Creates a QR code and returns it as a data URI string that can be embedded in HTML or used directly.
    Requires Node.js and qrcode package.
.PARAMETER Data
    The data to encode in the QR code.
.PARAMETER Size
    The size of the QR code in pixels. Default is 200.
.PARAMETER ErrorCorrectionLevel
    Error correction level: L (low ~7%), M (medium ~15%), Q (quartile ~25%), H (high ~30%). Default is M.
.PARAMETER DarkColor
    Color of the dark modules (foreground). Default is #000000 (black).
.PARAMETER LightColor
    Color of the light modules (background). Default is #FFFFFF (white).
.PARAMETER Margin
    Margin size in modules. Default is 4.
.EXAMPLE
    $dataUri = New-QrCodeDataUri -Data "https://example.com"
    Returns a data URI that can be used in HTML img tags.
#>
function New-QrCodeDataUri {
    param(
        [Parameter(Mandatory)]
        [string]$Data,
        [int]$Size = 200,
        [ValidateSet('L', 'M', 'Q', 'H')]
        [string]$ErrorCorrectionLevel = 'M',
        [string]$DarkColor = '#000000',
        [string]$LightColor = '#FFFFFF',
        [int]$Margin = 4
    )
    if (-not $global:DevToolsInitialized) { Ensure-DevTools }
    _New-QrCodeDataUri @PSBoundParameters
}

# Aliases
Set-Alias -Name qrcode-svg -Value New-QrCodeSvg -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-term -Value New-QrCodeTerminal -ErrorAction SilentlyContinue
Set-Alias -Name qrcode-uri -Value New-QrCodeDataUri -ErrorAction SilentlyContinue

