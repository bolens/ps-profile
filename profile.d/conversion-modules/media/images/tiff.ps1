# ===============================================
# TIFF Image Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes TIFF image format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for TIFF format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    TIFF is the Tagged Image File Format, commonly used for high-quality images.
#>
function Initialize-FileConversion-MediaImagesTiff {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-ImageFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaImagesCommon
    }

    # TIFF conversions
    Set-Item -Path Function:Global:_ConvertFrom-TiffToPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(tiff|tif)$', '.png' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-TiffToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(tiff|tif)$', '.jpg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-TiffToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(tiff|tif)$', '.pdf' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-TiffFromPng -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Compression = 'lzw')
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.png$', '.tiff' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'compress' = $Compression }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-TiffFromJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Compression = 'jpeg')
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(jpg|jpeg)$', '.tiff' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'compress' = $Compression }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-TiffFromPdf -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Compression = 'lzw')
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.pdf$', '.tiff' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'compress' = $Compression }
    } -Force
}

# TIFF conversion functions
<#
.SYNOPSIS
    Converts TIFF image to PNG format.
.DESCRIPTION
    Converts a TIFF image file to PNG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input TIFF file.
.PARAMETER OutputPath
    Path for the output PNG file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertFrom-TiffToPng -InputPath "image.tiff" -OutputPath "image.png"
#>
function ConvertFrom-TiffToPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-TiffToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-TiffToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-TiffToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert TIFF to PNG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'tiff-to-png' -Target 'ConvertFrom-TiffToPng'
    Set-AgentModeAlias -Name 'tif-to-png' -Target 'ConvertFrom-TiffToPng'
}
else {
    Set-Alias -Name tiff-to-png -Value ConvertFrom-TiffToPng -ErrorAction SilentlyContinue
    Set-Alias -Name tif-to-png -Value ConvertFrom-TiffToPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts TIFF image to JPEG format.
.DESCRIPTION
    Converts a TIFF image file to JPEG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input TIFF file.
.PARAMETER OutputPath
    Path for the output JPEG file. If not specified, uses input path with .jpg extension.
.PARAMETER Quality
    JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-TiffToJpeg -InputPath "image.tiff" -OutputPath "image.jpg" -Quality 95
#>
function ConvertFrom-TiffToJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-TiffToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-TiffToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-TiffToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert TIFF to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'tiff-to-jpeg' -Target 'ConvertFrom-TiffToJpeg'
    Set-AgentModeAlias -Name 'tiff-to-jpg' -Target 'ConvertFrom-TiffToJpeg'
    Set-AgentModeAlias -Name 'tif-to-jpeg' -Target 'ConvertFrom-TiffToJpeg'
    Set-AgentModeAlias -Name 'tif-to-jpg' -Target 'ConvertFrom-TiffToJpeg'
}
else {
    Set-Alias -Name tiff-to-jpeg -Value ConvertFrom-TiffToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name tiff-to-jpg -Value ConvertFrom-TiffToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name tif-to-jpeg -Value ConvertFrom-TiffToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name tif-to-jpg -Value ConvertFrom-TiffToJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts TIFF image to PDF format.
.DESCRIPTION
    Converts a TIFF image file to PDF format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input TIFF file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-TiffToPdf -InputPath "image.tiff" -OutputPath "image.pdf"
#>
function ConvertFrom-TiffToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-TiffToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-TiffToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-TiffToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert TIFF to PDF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'tiff-to-pdf' -Target 'ConvertFrom-TiffToPdf'
    Set-AgentModeAlias -Name 'tif-to-pdf' -Target 'ConvertFrom-TiffToPdf'
}
else {
    Set-Alias -Name tiff-to-pdf -Value ConvertFrom-TiffToPdf -ErrorAction SilentlyContinue
    Set-Alias -Name tif-to-pdf -Value ConvertFrom-TiffToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PNG image to TIFF format.
.DESCRIPTION
    Converts a PNG image file to TIFF format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input PNG file.
.PARAMETER OutputPath
    Path for the output TIFF file. If not specified, uses input path with .tiff extension.
.PARAMETER Compression
    TIFF compression method (default: lzw). Options: none, lzw, zip, jpeg.
.EXAMPLE
    ConvertTo-TiffFromPng -InputPath "image.png" -OutputPath "image.tiff" -Compression zip
#>
function ConvertTo-TiffFromPng {
    param([string]$InputPath, [string]$OutputPath, [string]$Compression = 'lzw')
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-TiffFromPng -ErrorAction SilentlyContinue) {
            _ConvertTo-TiffFromPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-TiffFromPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PNG to TIFF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'png-to-tiff' -Target 'ConvertTo-TiffFromPng'
    Set-AgentModeAlias -Name 'png-to-tif' -Target 'ConvertTo-TiffFromPng'
}
else {
    Set-Alias -Name png-to-tiff -Value ConvertTo-TiffFromPng -ErrorAction SilentlyContinue
    Set-Alias -Name png-to-tif -Value ConvertTo-TiffFromPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JPEG image to TIFF format.
.DESCRIPTION
    Converts a JPEG image file to TIFF format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input JPEG file.
.PARAMETER OutputPath
    Path for the output TIFF file. If not specified, uses input path with .tiff extension.
.PARAMETER Compression
    TIFF compression method (default: jpeg). Options: none, lzw, zip, jpeg.
.EXAMPLE
    ConvertTo-TiffFromJpeg -InputPath "image.jpg" -OutputPath "image.tiff" -Compression lzw
#>
function ConvertTo-TiffFromJpeg {
    param([string]$InputPath, [string]$OutputPath, [string]$Compression = 'jpeg')
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-TiffFromJpeg -ErrorAction SilentlyContinue) {
            _ConvertTo-TiffFromJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-TiffFromJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JPEG to TIFF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jpeg-to-tiff' -Target 'ConvertTo-TiffFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-tiff' -Target 'ConvertTo-TiffFromJpeg'
    Set-AgentModeAlias -Name 'jpeg-to-tif' -Target 'ConvertTo-TiffFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-tif' -Target 'ConvertTo-TiffFromJpeg'
}
else {
    Set-Alias -Name jpeg-to-tiff -Value ConvertTo-TiffFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-tiff -Value ConvertTo-TiffFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpeg-to-tif -Value ConvertTo-TiffFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-tif -Value ConvertTo-TiffFromJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PDF to TIFF format.
.DESCRIPTION
    Converts a PDF file to TIFF format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input PDF file.
.PARAMETER OutputPath
    Path for the output TIFF file. If not specified, uses input path with .tiff extension.
.PARAMETER Compression
    TIFF compression method (default: lzw). Options: none, lzw, zip, jpeg.
.EXAMPLE
    ConvertTo-TiffFromPdf -InputPath "document.pdf" -OutputPath "document.tiff" -Compression zip
#>
function ConvertTo-TiffFromPdf {
    param([string]$InputPath, [string]$OutputPath, [string]$Compression = 'lzw')
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-TiffFromPdf -ErrorAction SilentlyContinue) {
            _ConvertTo-TiffFromPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-TiffFromPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PDF to TIFF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'pdf-to-tiff' -Target 'ConvertTo-TiffFromPdf'
    Set-AgentModeAlias -Name 'pdf-to-tif' -Target 'ConvertTo-TiffFromPdf'
}
else {
    Set-Alias -Name pdf-to-tiff -Value ConvertTo-TiffFromPdf -ErrorAction SilentlyContinue
    Set-Alias -Name pdf-to-tif -Value ConvertTo-TiffFromPdf -ErrorAction SilentlyContinue
}

