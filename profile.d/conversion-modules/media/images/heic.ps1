# ===============================================
# HEIC/HEIF Image Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes HEIC/HEIF image format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HEIC/HEIF format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    HEIC/HEIF is Apple's High Efficiency Image Format.
#>
function Initialize-FileConversion-MediaImagesHeic {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-ImageFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaImagesCommon
    }

    # HEIC/HEIF conversions
    Set-Item -Path Function:Global:_ConvertFrom-HeicToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(heic|heif)$', '.jpg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-HeicToPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(heic|heif)$', '.png' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-HeicFromJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(jpg|jpeg)$', '.heic' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-HeicFromPng -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.png$', '.heic' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force
}

# HEIC/HEIF conversion functions
<#
.SYNOPSIS
    Converts HEIC/HEIF image to JPEG format.
.DESCRIPTION
    Converts a HEIC/HEIF image file to JPEG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input HEIC/HEIF file.
.PARAMETER OutputPath
    Path for the output JPEG file. If not specified, uses input path with .jpg extension.
.PARAMETER Quality
    JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-HeicToJpeg -InputPath "image.heic" -OutputPath "image.jpg" -Quality 95
#>
function ConvertFrom-HeicToJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-HeicToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-HeicToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-HeicToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HEIC to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'heic-to-jpeg' -Target 'ConvertFrom-HeicToJpeg'
    Set-AgentModeAlias -Name 'heic-to-jpg' -Target 'ConvertFrom-HeicToJpeg'
    Set-AgentModeAlias -Name 'heif-to-jpeg' -Target 'ConvertFrom-HeicToJpeg'
    Set-AgentModeAlias -Name 'heif-to-jpg' -Target 'ConvertFrom-HeicToJpeg'
}
else {
    Set-Alias -Name heic-to-jpeg -Value ConvertFrom-HeicToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name heic-to-jpg -Value ConvertFrom-HeicToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name heif-to-jpeg -Value ConvertFrom-HeicToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name heif-to-jpg -Value ConvertFrom-HeicToJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts HEIC/HEIF image to PNG format.
.DESCRIPTION
    Converts a HEIC/HEIF image file to PNG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input HEIC/HEIF file.
.PARAMETER OutputPath
    Path for the output PNG file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertFrom-HeicToPng -InputPath "image.heic" -OutputPath "image.png"
#>
function ConvertFrom-HeicToPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-HeicToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-HeicToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-HeicToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert HEIC to PNG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'heic-to-png' -Target 'ConvertFrom-HeicToPng'
    Set-AgentModeAlias -Name 'heif-to-png' -Target 'ConvertFrom-HeicToPng'
}
else {
    Set-Alias -Name heic-to-png -Value ConvertFrom-HeicToPng -ErrorAction SilentlyContinue
    Set-Alias -Name heif-to-png -Value ConvertFrom-HeicToPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JPEG image to HEIC format.
.DESCRIPTION
    Converts a JPEG image file to HEIC format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input JPEG file.
.PARAMETER OutputPath
    Path for the output HEIC file. If not specified, uses input path with .heic extension.
.PARAMETER Quality
    HEIC quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-HeicFromJpeg -InputPath "image.jpg" -OutputPath "image.heic" -Quality 95
#>
function ConvertTo-HeicFromJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-HeicFromJpeg -ErrorAction SilentlyContinue) {
            _ConvertTo-HeicFromJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HeicFromJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JPEG to HEIC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jpeg-to-heic' -Target 'ConvertTo-HeicFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-heic' -Target 'ConvertTo-HeicFromJpeg'
    Set-AgentModeAlias -Name 'jpeg-to-heif' -Target 'ConvertTo-HeicFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-heif' -Target 'ConvertTo-HeicFromJpeg'
}
else {
    Set-Alias -Name jpeg-to-heic -Value ConvertTo-HeicFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-heic -Value ConvertTo-HeicFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpeg-to-heif -Value ConvertTo-HeicFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-heif -Value ConvertTo-HeicFromJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PNG image to HEIC format.
.DESCRIPTION
    Converts a PNG image file to HEIC format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input PNG file.
.PARAMETER OutputPath
    Path for the output HEIC file. If not specified, uses input path with .heic extension.
.PARAMETER Quality
    HEIC quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-HeicFromPng -InputPath "image.png" -OutputPath "image.heic" -Quality 95
#>
function ConvertTo-HeicFromPng {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-HeicFromPng -ErrorAction SilentlyContinue) {
            _ConvertTo-HeicFromPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-HeicFromPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PNG to HEIC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'png-to-heic' -Target 'ConvertTo-HeicFromPng'
    Set-AgentModeAlias -Name 'png-to-heif' -Target 'ConvertTo-HeicFromPng'
}
else {
    Set-Alias -Name png-to-heic -Value ConvertTo-HeicFromPng -ErrorAction SilentlyContinue
    Set-Alias -Name png-to-heif -Value ConvertTo-HeicFromPng -ErrorAction SilentlyContinue
}

