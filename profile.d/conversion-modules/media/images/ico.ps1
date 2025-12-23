# ===============================================
# ICO Image Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes ICO image format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for ICO format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    ICO is the Windows icon format.
#>
function Initialize-FileConversion-MediaImagesIco {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-ImageFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaImagesCommon
    }

    # ICO conversions
    Set-Item -Path Function:Global:_ConvertFrom-IcoToPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ico$', '.png' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-IcoToJpeg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ico$', '.jpg' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath -Options @{ 'quality' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-IcoFromPng -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.png$', '.ico' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force

    Set-Item -Path Function:Global:_ConvertTo-IcoFromJpeg -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.(jpg|jpeg)$', '.ico' }
        _Convert-ImageFormat -InputPath $InputPath -OutputPath $OutputPath
    } -Force
}

# ICO conversion functions
<#
.SYNOPSIS
    Converts ICO image to PNG format.
.DESCRIPTION
    Converts an ICO image file to PNG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input ICO file.
.PARAMETER OutputPath
    Path for the output PNG file. If not specified, uses input path with .png extension.
.EXAMPLE
    ConvertFrom-IcoToPng -InputPath "icon.ico" -OutputPath "icon.png"
#>
function ConvertFrom-IcoToPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-IcoToPng -ErrorAction SilentlyContinue) {
            _ConvertFrom-IcoToPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-IcoToPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ICO to PNG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ico-to-png' -Target 'ConvertFrom-IcoToPng'
}
else {
    Set-Alias -Name ico-to-png -Value ConvertFrom-IcoToPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts ICO image to JPEG format.
.DESCRIPTION
    Converts an ICO image file to JPEG format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input ICO file.
.PARAMETER OutputPath
    Path for the output JPEG file. If not specified, uses input path with .jpg extension.
.PARAMETER Quality
    JPEG quality (1-100, default: 90). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-IcoToJpeg -InputPath "icon.ico" -OutputPath "icon.jpg" -Quality 95
#>
function ConvertFrom-IcoToJpeg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 90)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-IcoToJpeg -ErrorAction SilentlyContinue) {
            _ConvertFrom-IcoToJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-IcoToJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert ICO to JPEG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ico-to-jpeg' -Target 'ConvertFrom-IcoToJpeg'
    Set-AgentModeAlias -Name 'ico-to-jpg' -Target 'ConvertFrom-IcoToJpeg'
}
else {
    Set-Alias -Name ico-to-jpeg -Value ConvertFrom-IcoToJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name ico-to-jpg -Value ConvertFrom-IcoToJpeg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts PNG image to ICO format.
.DESCRIPTION
    Converts a PNG image file to ICO format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input PNG file.
.PARAMETER OutputPath
    Path for the output ICO file. If not specified, uses input path with .ico extension.
.EXAMPLE
    ConvertTo-IcoFromPng -InputPath "icon.png" -OutputPath "icon.ico"
#>
function ConvertTo-IcoFromPng {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-IcoFromPng -ErrorAction SilentlyContinue) {
            _ConvertTo-IcoFromPng @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-IcoFromPng not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert PNG to ICO: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'png-to-ico' -Target 'ConvertTo-IcoFromPng'
}
else {
    Set-Alias -Name png-to-ico -Value ConvertTo-IcoFromPng -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts JPEG image to ICO format.
.DESCRIPTION
    Converts a JPEG image file to ICO format using ImageMagick or GraphicsMagick.
.PARAMETER InputPath
    Path to the input JPEG file.
.PARAMETER OutputPath
    Path for the output ICO file. If not specified, uses input path with .ico extension.
.EXAMPLE
    ConvertTo-IcoFromJpeg -InputPath "icon.jpg" -OutputPath "icon.ico"
#>
function ConvertTo-IcoFromJpeg {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertTo-IcoFromJpeg -ErrorAction SilentlyContinue) {
            _ConvertTo-IcoFromJpeg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertTo-IcoFromJpeg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert JPEG to ICO: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'jpeg-to-ico' -Target 'ConvertTo-IcoFromJpeg'
    Set-AgentModeAlias -Name 'jpg-to-ico' -Target 'ConvertTo-IcoFromJpeg'
}
else {
    Set-Alias -Name jpeg-to-ico -Value ConvertTo-IcoFromJpeg -ErrorAction SilentlyContinue
    Set-Alias -Name jpg-to-ico -Value ConvertTo-IcoFromJpeg -ErrorAction SilentlyContinue
}

