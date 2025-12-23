# ===============================================
# SVG Image Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes SVG image format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for SVG format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    SVG is a vector format, so conversions may require rasterization at specific sizes.
#>
function Initialize-FileConversion-MediaImagesSvg {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-ImageFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaImagesCommon
    }

    # SVG conversions
    Set-Item -Path Function:Global:_ConvertFrom-SvgToPng -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Width = 1024, [int]$Height = 1024)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.svg$', '.png' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'resize' = "${Width}x${Height}" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-SvgToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Width = 1024, [int]$Height = 1024, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.svg$', '.jpg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'resize' = "${Width}x${Height}"; 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-SvgToPdf -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.svg$', '.pdf' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-SvgFromPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.png$', '.svg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-SvgFromJpeg -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(jpg|jpeg)$', '.svg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force
}

# SVG conversion functions
<#
.SYNOPSIS
    Converts SVG image to PNG format.
.DESCRIPTION
    Converts an SVG image file to PNG format using ImageMagick or GraphicsMagick.
    SVG is rasterized at the specified dimensions.
.PARAMETER InputPath
    Path to the input SVG file.
.PARAMETER OutputPath
    Path for the output PNG file. If not specified, uses input path with .png extension.
.PARAMETER Width
    Output width in pixels (default: 1024).
.PARAMETER Height
    Output height in pixels (default: 1024).
.EXAMPLE
    ConvertFrom-SvgToPng -InputPath "image.svg" -OutputPath "image.png" -Width 2048 -Height 2048
#>
function ConvertFrom-SvgToPng {
    param([string]$InputPath, [string]$OutputPath, [int]$Width = 1024, [int]$Height = 1024)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-SvgToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-SvgToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-SvgToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert SVG to PNG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'svg-to-png' -Target 'ConvertFrom-SvgToPng'
}
else {
    Set-Alias -Name svg-to-png -Value ConvertFrom-SvgToPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts SVG image to JPEG format.
.DESCRIPTION
    Converts an SVG image file to JPEG format using ImageMagick or GraphicsMagick.
    SVG is rasterized at the specified dimensions.
.PARAMETER InputPath
    Path to the input SVG file.
.PARAMETER OutputPath
    Path for the output JPEG file. If not specified, uses input path with .jpg extension.
.PARAMETER Width
    Output width in pixels (default: 1024).
.PARAMETER Height
    Output height in pixels (default: 1024).
.PARAMETER Quality
    JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-SvgToJpeg -InputPath "image.svg" -OutputPath "image.jpg" -Width 2048 -Height 2048 -Quality 95
#>
function ConvertFrom-SvgToJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Width = 1024, [int]$Height = 1024, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-SvgToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-SvgToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-SvgToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert SVG to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'svg-to-jpeg' -Target 'ConvertFrom-SvgToJpeg'
    Set-AgentModeAlias -Name 'svg-to-jpg' -Target 'ConvertFrom-SvgToJpeg'
}
else {
    Set-Alias -Name svg-to-jpeg -Value ConvertFrom-SvgToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name svg-to-jpg -Value ConvertFrom-SvgToJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts SVG image to PDF format.
.DESCRIPTION
    Converts an SVG image file to PDF format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input SVG file.
.PARAMETER OutputPath
    Path for the output PDF file. If not specified, uses input path with .pdf extension.
.EXAMPLE
    ConvertFrom-SvgToPdf -InputPath "image.svg" -OutputPath "image.pdf"
#>
function ConvertFrom-SvgToPdf {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-SvgToPdf -ErrorAction SilentlyContinue) {
            _ConvertFrom-SvgToPdf @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-SvgToPdf not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert SVG to PDF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'svg-to-pdf' -Target 'ConvertFrom-SvgToPdf'
}
else {
    Set-Alias -Name svg-to-pdf -Value ConvertFrom-SvgToPdf -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PNG image to SVG format.
.DESCRIPTION
    Converts a PNG image file to SVG format using ImageMagick or GraphicsMagick.
    Note: This creates a raster image embedded in SVG, not a true vector conversion.
.PARAMETER InputPath
    Path to the input PNG file.
.PARAMETER OutputPath
    Path for the output SVG file. If not specified, uses input path with .svg extension.
.EXAMPLE
    ConvertTo-SvgFromPng -InputPath "image.png" -OutputPath "image.svg"
#>
function ConvertTo-SvgFromPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-SvgFromPng -ErrorAction SilentlyContinue) {
            _ConvertTo-SvgFromPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-SvgFromPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PNG to SVG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'png-to-svg' -Target 'ConvertTo-SvgFromPng'
}
else {
    Set-Alias -Name png-to-svg -Value ConvertTo-SvgFromPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JPEG image to SVG format.
.DESCRIPTION
    Converts a JPEG image file to SVG format using ImageMagick or GraphicsMagick.
    Note: This creates a raster image embedded in SVG, not a true vector conversion.
.PARAMETER InputPath
    Path to the input JPEG file.
.PARAMETER OutputPath
    Path for the output SVG file. If not specified, uses input path with .svg extension.
.EXAMPLE
    ConvertTo-SvgFromJpeg -InputPath "image.jpg" -OutputPath "image.svg"
#>
function ConvertTo-SvgFromJpeg {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-SvgFromJpeg -ErrorAction SilentlyContinue) {
            _ConvertTo-SvgFromJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-SvgFromJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JPEG to SVG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jpeg-to-svg' -Target 'ConvertTo-SvgFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-svg' -Target 'ConvertTo-SvgFromJpeg'
}
else {
    Set-Alias -Name jpeg-to-svg -Value ConvertTo-SvgFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-svg -Value ConvertTo-SvgFromJpeg -ErrorAction SilentlyContinue
}

