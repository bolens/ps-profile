# ===============================================
# BMP Image Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes BMP image format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for BMP format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    BMP is the Windows Bitmap format.
#>
function Initialize-FileConversion-MediaImagesBmp {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-ImageFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaImagesCommon
    }

    # BMP conversions
    Set-Item -Path Function:Global:_ConvertFrom-BmpToPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.bmp$', '.png' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-BmpToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.bmp$', '.jpg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-BmpFromPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.png$', '.bmp' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-BmpFromJpeg -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(jpg|jpeg)$', '.bmp' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force
}

# BMP conversion functions
<#
.SYNOPSIS
    Converts BMP image to PNG format.
.DESCRIPTION
    Converts a BMP image file to PNG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input BMP file.
.PARAMETER OutputPath
    Path for the output PNG file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertFrom-BmpToPng -InputPath "image.bmp" -OutputPath "image.png"
#>
function ConvertFrom-BmpToPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-BmpToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-BmpToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-BmpToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert BMP to PNG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'bmp-to-png' -Target 'ConvertFrom-BmpToPng'
}
else {
    Set-Alias -Name bmp-to-png -Value ConvertFrom-BmpToPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts BMP image to JPEG format.
.DESCRIPTION
    Converts a BMP image file to JPEG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input BMP file.
.PARAMETER OutputPath
    Path for the output JPEG file. If not specified, uses input path with .jpg extension.
.PARAMETER Quality
    JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-BmpToJpeg -InputPath "image.bmp" -OutputPath "image.jpg" -Quality 95
#>
function ConvertFrom-BmpToJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-BmpToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-BmpToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-BmpToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert BMP to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'bmp-to-jpeg' -Target 'ConvertFrom-BmpToJpeg'
    Set-AgentModeAlias -Name 'bmp-to-jpg' -Target 'ConvertFrom-BmpToJpeg'
}
else {
    Set-Alias -Name bmp-to-jpeg -Value ConvertFrom-BmpToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name bmp-to-jpg -Value ConvertFrom-BmpToJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PNG image to BMP format.
.DESCRIPTION
    Converts a PNG image file to BMP format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input PNG file.
.PARAMETER OutputPath
    Path for the output BMP file. If not specified, uses input path with .bmp extension.
.EXAMPLE
    ConvertTo-BmpFromPng -InputPath "image.png" -OutputPath "image.bmp"
#>
function ConvertTo-BmpFromPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-BmpFromPng -ErrorAction SilentlyContinue) {
            _ConvertTo-BmpFromPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-BmpFromPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PNG to BMP: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'png-to-bmp' -Target 'ConvertTo-BmpFromPng'
}
else {
    Set-Alias -Name png-to-bmp -Value ConvertTo-BmpFromPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JPEG image to BMP format.
.DESCRIPTION
    Converts a JPEG image file to BMP format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input JPEG file.
.PARAMETER OutputPath
    Path for the output BMP file. If not specified, uses input path with .bmp extension.
.EXAMPLE
    ConvertTo-BmpFromJpeg -InputPath "image.jpg" -OutputPath "image.bmp"
#>
function ConvertTo-BmpFromJpeg {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-BmpFromJpeg -ErrorAction SilentlyContinue) {
            _ConvertTo-BmpFromJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-BmpFromJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JPEG to BMP: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jpeg-to-bmp' -Target 'ConvertTo-BmpFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-bmp' -Target 'ConvertTo-BmpFromJpeg'
}
else {
    Set-Alias -Name jpeg-to-bmp -Value ConvertTo-BmpFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-bmp -Value ConvertTo-BmpFromJpeg -ErrorAction SilentlyContinue
}

