# ===============================================
# Image media format conversion utilities
# Image conversion and resizing
# ===============================================

<#
.SYNOPSIS
    Initializes image media format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for image format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaImages {
    # Image convert
    Set-Item -Path Function:Global:_Convert-Image -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            magick $InputPath $OutputPath 2>$null
        }
        catch {
            Write-Error "Failed to convert image: $_"
        }
    } -Force

    # Image resize
    Set-Item -Path Function:Global:_Resize-Image -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Width, [int]$Height)
        try {
            if (-not $OutputPath) { $OutputPath = $InputPath }
            magick $InputPath -resize ${Width}x${Height} $OutputPath 2>$null
        }
        catch {
            Write-Error "Failed to resize image: $_"
        }
    } -Force
}

# Convert image formats
<#
.SYNOPSIS
    Converts image file formats.
.DESCRIPTION
    Uses ImageMagick to convert an image from one format to another.
.PARAMETER InputPath
    The path to the input image file.
.PARAMETER OutputPath
    The path for the output image file with desired format.
#>
function Convert-Image {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    _Convert-Image @PSBoundParameters
}
Set-Alias -Name image-convert -Value Convert-Image -ErrorAction SilentlyContinue

# Resize image
<#
.SYNOPSIS
    Resizes an image.
.DESCRIPTION
    Uses ImageMagick to resize an image to specified dimensions.
.PARAMETER InputPath
    The path to the input image file.
.PARAMETER OutputPath
    The path for the output image file.
.PARAMETER Width
    The desired width.
.PARAMETER Height
    The desired height.
#>
function Resize-Image {
    param([string]$InputPath, [string]$OutputPath, [int]$Width, [int]$Height)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    _Resize-Image @PSBoundParameters
}
Set-Alias -Name image-resize -Value Resize-Image -ErrorAction SilentlyContinue

