# ===============================================
# HEX Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes HEX color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HEX color format conversions.
    Supports converting between HEX and RGB.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    HEX format supports #rgb, #rrggbb, and #rrggbbaa formats.
#>
function Initialize-FileConversion-MediaColorsHex {
    # Convert RGB to HEX
    Set-Item -Path Function:Global:_Convert-RgbToHex -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue,
            [switch]$IncludeAlpha,
            [double]$Alpha = 1.0
        )
        
        $redClamped = [Math]::Max(0, [Math]::Min(255, $Red))
        $greenClamped = [Math]::Max(0, [Math]::Min(255, $Green))
        $blueClamped = [Math]::Max(0, [Math]::Min(255, $Blue))
        
        $hex = '#' + $redClamped.ToString('X2') + $greenClamped.ToString('X2') + $blueClamped.ToString('X2')
        
        if ($IncludeAlpha) {
            $alphaClamped = [Math]::Max(0, [Math]::Min(255, [int]($Alpha * 255)))
            $hex += $alphaClamped.ToString('X2')
        }
        
        return $hex
    } -Force
}

