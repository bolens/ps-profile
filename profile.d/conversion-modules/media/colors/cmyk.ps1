# ===============================================
# CMYK/CMYKA Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes CMYK/CMYKA color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for CMYK/CMYKA color format conversions.
    Supports converting between CMYK and RGB.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    CMYK conversions follow standard printing color model specifications.
#>
function Initialize-FileConversion-MediaColorsCmyk {
    # Convert CMYK to RGB
    Set-Item -Path Function:Global:_Convert-CmykToRgb -Value {
        param(
            [double]$Cyan,
            [double]$Magenta,
            [double]$Yellow,
            [double]$Key
        )
        
        $cyanNormalized = [Math]::Max(0, [Math]::Min(1, $Cyan))
        $magentaNormalized = [Math]::Max(0, [Math]::Min(1, $Magenta))
        $yellowNormalized = [Math]::Max(0, [Math]::Min(1, $Yellow))
        $keyNormalized = [Math]::Max(0, [Math]::Min(1, $Key))
        
        $redComponent = (1 - $cyanNormalized) * (1 - $keyNormalized) * 255
        $greenComponent = (1 - $magentaNormalized) * (1 - $keyNormalized) * 255
        $blueComponent = (1 - $yellowNormalized) * (1 - $keyNormalized) * 255
        
        return @{
            r = [Math]::Round($redComponent)
            g = [Math]::Round($greenComponent)
            b = [Math]::Round($blueComponent)
        }
    } -Force

    # Convert RGB to CMYK
    Set-Item -Path Function:Global:_Convert-RgbToCmyk -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
        
        $redNormalized = $Red / 255.0
        $greenNormalized = $Green / 255.0
        $blueNormalized = $Blue / 255.0
        
        $key = 1 - [Math]::Max($redNormalized, [Math]::Max($greenNormalized, $blueNormalized))
        
        if ($key -eq 1) {
            return @{ c = 0; m = 0; y = 0; k = 100 }
        }
        
        $cyan = (1 - $redNormalized - $key) / (1 - $key)
        $magenta = (1 - $greenNormalized - $key) / (1 - $key)
        $yellow = (1 - $blueNormalized - $key) / (1 - $key)
        
        return @{
            c = [Math]::Round($cyan * 100, 2)
            m = [Math]::Round($magenta * 100, 2)
            y = [Math]::Round($yellow * 100, 2)
            k = [Math]::Round($key * 100, 2)
        }
    } -Force
}

