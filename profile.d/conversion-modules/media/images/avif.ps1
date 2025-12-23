# ===============================================
# AVIF Image Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes AVIF image format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for AVIF format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaImagesAvif {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-ImageFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaImagesCommon
    }

    # AVIF conversions
    Set-Item -Path Function:Global:_ConvertFrom-AvifToPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.avif$', '.png' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-AvifToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.avif$', '.jpg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-AvifToWebp -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.avif$', '.webp' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-AvifFromPng -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.png$', '.avif' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-AvifFromJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(jpg|jpeg)$', '.avif' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-AvifFromWebp -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.webp$', '.avif' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force
}

# AVIF conversion functions
<#
.SYNOPSIS
    Converts AVIF image to PNG format.
.DESCRIPTION
    Converts an AVIF image file to PNG format using ImageMagick.
.PARAMETER InputPath
    Path to the input AVIF file.
.PARAMETER OutputPath
    Path for the output PNG file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertFrom-AvifToPng -InputPath "image.avif" -OutputPath "image.png"
#>
function ConvertFrom-AvifToPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AvifToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-AvifToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AvifToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AVIF to PNG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'avif-to-png' -Target 'ConvertFrom-AvifToPng'
}
else {
    Set-Alias -Name avif-to-png -Value ConvertFrom-AvifToPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AVIF image to JPEG format.
.DESCRIPTION
    Converts an AVIF image file to JPEG format using ImageMagick.
.PARAMETER InputPath
    Path to the input AVIF file.
.PARAMETER OutputPath
    Path for the output JPEG file. If not specified, uses input path with .jpg extension.
.PARAMETER Quality
    JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-AvifToJpeg -InputPath "image.avif" -OutputPath "image.jpg" -Quality 95
#>
function ConvertFrom-AvifToJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AvifToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-AvifToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AvifToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AVIF to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'avif-to-jpeg' -Target 'ConvertFrom-AvifToJpeg'
    Set-AgentModeAlias -Name 'avif-to-jpg' -Target 'ConvertFrom-AvifToJpeg'
}
else {
    Set-Alias -Name avif-to-jpeg -Value ConvertFrom-AvifToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name avif-to-jpg -Value ConvertFrom-AvifToJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AVIF image to WebP format.
.DESCRIPTION
    Converts an AVIF image file to WebP format using ImageMagick.
.PARAMETER InputPath
    Path to the input AVIF file.
.PARAMETER OutputPath
    Path for the output WebP file. If not specified, uses input path with .webp extension.
.PARAMETER Quality
    WebP quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-AvifToWebp -InputPath "image.avif" -OutputPath "image.webp" -Quality 95
#>
function ConvertFrom-AvifToWebp {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AvifToWebp -ErrorAction SilentlyContinue) {
            _ConvertFrom-AvifToWebp @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AvifToWebp not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AVIF to WebP: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'avif-to-webp' -Target 'ConvertFrom-AvifToWebp'
}
else {
    Set-Alias -Name avif-to-webp -Value ConvertFrom-AvifToWebp -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PNG image to AVIF format.
.DESCRIPTION
    Converts a PNG image file to AVIF format using ImageMagick.
.PARAMETER InputPath
    Path to the input PNG file.
.PARAMETER OutputPath
    Path for the output AVIF file. If not specified, uses input path with .avif extension.
.PARAMETER Quality
    AVIF quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-AvifFromPng -InputPath "image.png" -OutputPath "image.avif" -Quality 95
#>
function ConvertTo-AvifFromPng {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-AvifFromPng -ErrorAction SilentlyContinue) {
            _ConvertTo-AvifFromPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-AvifFromPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PNG to AVIF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'png-to-avif' -Target 'ConvertTo-AvifFromPng'
}
else {
    Set-Alias -Name png-to-avif -Value ConvertTo-AvifFromPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JPEG image to AVIF format.
.DESCRIPTION
    Converts a JPEG image file to AVIF format using ImageMagick.
.PARAMETER InputPath
    Path to the input JPEG file.
.PARAMETER OutputPath
    Path for the output AVIF file. If not specified, uses input path with .avif extension.
.PARAMETER Quality
    AVIF quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-AvifFromJpeg -InputPath "image.jpg" -OutputPath "image.avif" -Quality 95
#>
function ConvertTo-AvifFromJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-AvifFromJpeg -ErrorAction SilentlyContinue) {
            _ConvertTo-AvifFromJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-AvifFromJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JPEG to AVIF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jpeg-to-avif' -Target 'ConvertTo-AvifFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-avif' -Target 'ConvertTo-AvifFromJpeg'
}
else {
    Set-Alias -Name jpeg-to-avif -Value ConvertTo-AvifFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-avif -Value ConvertTo-AvifFromJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts WebP image to AVIF format.
.DESCRIPTION
    Converts a WebP image file to AVIF format using ImageMagick.
.PARAMETER InputPath
    Path to the input WebP file.
.PARAMETER OutputPath
    Path for the output AVIF file. If not specified, uses input path with .avif extension.
.PARAMETER Quality
    AVIF quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertTo-AvifFromWebp -InputPath "image.webp" -OutputPath "image.avif" -Quality 95
#>
function ConvertTo-AvifFromWebp {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-AvifFromWebp -ErrorAction SilentlyContinue) {
            _ConvertTo-AvifFromWebp @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-AvifFromWebp not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WebP to AVIF: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'webp-to-avif' -Target 'ConvertTo-AvifFromWebp'
}
else {
    Set-Alias -Name webp-to-avif -Value ConvertTo-AvifFromWebp -ErrorAction SilentlyContinue
}

