# ===============================================
# WebP Image Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes WebP image format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for WebP format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaImagesWebp {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-ImageFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaImagesCommon
    }

    # WebP conversions
    Set-Item -Path Function:Global:_ConvertFrom-WebpToPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.webp$', '.png' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WebpToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.webp$', '.jpg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WebpToGif -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.webp$', '.gif' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-WebpFromPng -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.png$', '.webp' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-WebpFromJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(jpg|jpeg)$', '.webp' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-WebpFromGif -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.gif$', '.webp' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force
}

# WebP conversion functions
<#
.SYNOPSIS
    Converts WebP image to PNG format.
.DESCRIPTION
    Converts a WebP image file to PNG format using ImageMagick.
.PARAMETER InputPath
    Path to the input WebP file.
.PARAMETER OutputPath
    Path for the output PNG file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertFrom-WebpToPng -InputPath "image.webp" -OutputPath "image.png"
#>
function ConvertFrom-WebpToPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WebpToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-WebpToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WebpToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WebP to PNG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'webp-to-png' -Target 'ConvertFrom-WebpToPng'
}
else {
    Set-Alias -Name webp-to-png -Value ConvertFrom-WebpToPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts WebP image to JPEG format.
.DESCRIPTION
    Converts a WebP image file to JPEG format using ImageMagick.
.PARAMETER InputPath
    Path to the input WebP file.
.PARAMETER OutputPath
    Path for the output JPEG file. If not specified, uses input path with .jpg extension.
.PARAMETER Quality
    JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-WebpToJpeg -InputPath "image.webp" -OutputPath "image.jpg" -Quality 95
#>
function ConvertFrom-WebpToJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WebpToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-WebpToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WebpToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WebP to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'webp-to-jpeg' -Target 'ConvertFrom-WebpToJpeg'
    Set-AgentModeAlias -Name 'webp-to-jpg' -Target 'ConvertFrom-WebpToJpeg'
}
else {
    Set-Alias -Name webp-to-jpeg -Value ConvertFrom-WebpToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name webp-to-jpg -Value ConvertFrom-WebpToJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts WebP image to GIF format.
.DESCRIPTION
    Converts a WebP image file to GIF format using ImageMagick.
.PARAMETER InputPath
    Path to the input WebP file.
.PARAMETER OutputPath
    Path for the output GIF file. If not specified, uses input path with .gif extension.
.EXAMPLE
    ConvertFrom-WebpToGif -InputPath "image.webp" -OutputPath "image.gif"
#>
function ConvertFrom-WebpToGif {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WebpToGif -ErrorAction SilentlyContinue) {
            _ConvertFrom-WebpToGif @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WebpToGif not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WebP to GIF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'webp-to-gif' -Target 'ConvertFrom-WebpToGif'
}
else {
    Set-Alias -Name webp-to-gif -Value ConvertFrom-WebpToGif -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PNG image to WebP format.
.DESCRIPTION
    Converts a PNG image file to WebP format using ImageMagick.
.PARAMETER InputPath
    Path to the input PNG file.
.PARAMETER OutputPath
    Path for the output WebP file. If not specified, uses input path with .webp extension.
.PARAMETER Quality
    WebP quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-WebpFromPng -InputPath "image.png" -OutputPath "image.webp" -Quality 95
#>
function ConvertTo-WebpFromPng {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-WebpFromPng -ErrorAction SilentlyContinue) {
            _ConvertTo-WebpFromPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-WebpFromPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PNG to WebP: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'png-to-webp' -Target 'ConvertTo-WebpFromPng'
}
else {
    Set-Alias -Name png-to-webp -Value ConvertTo-WebpFromPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JPEG image to WebP format.
.DESCRIPTION
    Converts a JPEG image file to WebP format using ImageMagick.
.PARAMETER InputPath
    Path to the input JPEG file.
.PARAMETER OutputPath
    Path for the output WebP file. If not specified, uses input path with .webp extension.
.PARAMETER Quality
    WebP quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-WebpFromJpeg -InputPath "image.jpg" -OutputPath "image.webp" -Quality 95
#>
function ConvertTo-WebpFromJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-WebpFromJpeg -ErrorAction SilentlyContinue) {
            _ConvertTo-WebpFromJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-WebpFromJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JPEG to WebP: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jpeg-to-webp' -Target 'ConvertTo-WebpFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-webp' -Target 'ConvertTo-WebpFromJpeg'
}
else {
    Set-Alias -Name jpeg-to-webp -Value ConvertTo-WebpFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-webp -Value ConvertTo-WebpFromJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts GIF image to WebP format.
.DESCRIPTION
    Converts a GIF image file to WebP format using ImageMagick.
.PARAMETER InputPath
    Path to the input GIF file.
.PARAMETER OutputPath
    Path for the output WebP file. If not specified, uses input path with .webp extension.
.PARAMETER Quality
    WebP quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-WebpFromGif -InputPath "image.gif" -OutputPath "image.webp" -Quality 95
#>
function ConvertTo-WebpFromGif {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-WebpFromGif -ErrorAction SilentlyContinue) {
            _ConvertTo-WebpFromGif @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-WebpFromGif not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert GIF to WebP: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'gif-to-webp' -Target 'ConvertTo-WebpFromGif'
}
else {
    Set-Alias -Name gif-to-webp -Value ConvertTo-WebpFromGif -ErrorAction SilentlyContinue
}

