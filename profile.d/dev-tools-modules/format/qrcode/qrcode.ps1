# ===============================================
# QR code generation utilities
# ===============================================

<#
.SYNOPSIS
    Initializes QR code generation utility functions.
.DESCRIPTION
    Sets up internal functions for generating QR code images with various formats and options.
    This function is called automatically by Ensure-DevTools.
.NOTES
    This is an internal initialization function and should not be called directly.
    Requires Node.js and qrcode package.
#>
function Initialize-DevTools-QrCode {
    # Ensure NodeJs module is imported (use repo root from bootstrap if available)
    if (-not (Get-Command Invoke-NodeScript -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Variable -Name 'RepoRoot' -Scope Script -ErrorAction SilentlyContinue) {
            $script:RepoRoot
        }
        elseif (Get-Variable -Name 'BootstrapRoot' -Scope Script -ErrorAction SilentlyContinue) {
            Split-Path -Parent $script:BootstrapRoot
        }
        else {
            Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        }
        $nodeJsModulePath = Join-Path $repoRoot 'scripts' 'lib' 'NodeJs.psm1'
        if (Test-Path $nodeJsModulePath) {
            Import-Module $nodeJsModulePath -DisableNameChecking -ErrorAction SilentlyContinue -Global
        }
    }

    # Enhanced QR Code Generator with options
    Set-Item -Path Function:Global:_New-QrCode -Value {
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
                width                = $Size
                errorCorrectionLevel = $ErrorCorrectionLevel
                color                = @{
                    dark  = $DarkColor
                    light = $LightColor
                }
                margin               = $Margin
            } | ConvertTo-Json -Compress

            $tempScript = Join-Path $env:TEMP "qrcode-gen-$(Get-Random).js"
            Set-Content -LiteralPath $tempScript -Value $nodeScript -Encoding UTF8
            try {
                $result = Invoke-NodeScript -ScriptPath $tempScript -Arguments $Data, $OutputPath, $options
                if ($LASTEXITCODE -ne 0) {
                    throw "Node.js script failed: $result"
                }
                Write-Host "QR code generated: $OutputPath" -ForegroundColor Green
            }
            finally {
                Remove-Item -LiteralPath $tempScript -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Error "Failed to generate QR code: $_"
        }
    } -Force

    # Initialize sub-modules
    $qrcodeDir = $PSScriptRoot
    if (Test-Path $qrcodeDir) {
        . (Join-Path $qrcodeDir 'qrcode-formats.ps1')
        . (Join-Path $qrcodeDir 'qrcode-communication.ps1')
        . (Join-Path $qrcodeDir 'qrcode-specialized.ps1')
        
        # Call initialization functions from sub-modules
        Initialize-DevTools-QrCode-Formats
        Initialize-DevTools-QrCode-Communication
        Initialize-DevTools-QrCode-Specialized
    }
}

# Public functions and aliases
<#
.SYNOPSIS
    Generates a QR code image from data.
.DESCRIPTION
    Creates a QR code image file from the provided data with customizable options.
    Requires Node.js and qrcode package.
.PARAMETER Data
    The data to encode in the QR code.
.PARAMETER OutputPath
    The path where the QR code image will be saved.
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
    New-QrCode -Data "https://example.com" -OutputPath "qrcode.png"
    Generates a QR code for the URL.
.EXAMPLE
    New-QrCode -Data "Hello World" -OutputPath "hello.png" -Size 300 -ErrorCorrectionLevel H
    Generates a larger QR code with high error correction.
.EXAMPLE
    New-QrCode -Data "Custom Colors" -OutputPath "custom.png" -DarkColor "#FF0000" -LightColor "#FFFF00"
    Generates a QR code with red foreground and yellow background.
#>
function New-QrCode {
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
    _New-QrCode @PSBoundParameters
}

# Core alias
Set-Alias -Name qrcode -Value New-QrCode -ErrorAction SilentlyContinue

