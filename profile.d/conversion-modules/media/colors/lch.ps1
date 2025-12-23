# ===============================================
# LCH/LCHa Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes LCH/LCHa color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for LCH/LCHa (Lightness, Chroma, Hue) color format conversions.
    Supports converting between LCH and RGB via LAB intermediate color space.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    LCH conversions follow CSS Color Module Level 4 specifications.
    LCH is a perceptually uniform color space derived from LAB.
    Uses D65 white point and sRGB color space.
#>
function Initialize-FileConversion-MediaColorsLch {
    # Convert LAB to LCH
    Set-Item -Path Function:Global:_Convert-LabToLch -Value {
        param(
            [double]$L,
            [double]$A,
            [double]$B
        )
        
        $chroma = [Math]::Sqrt($A * $A + $B * $B)
        $hue = [Math]::Atan2($B, $A) * 180.0 / [Math]::PI
        
        # Normalize hue to 0-360
        if ($hue -lt 0) {
            $hue = $hue + 360.0
        }
        
        return @{
            l = [Math]::Round($L, 2)
            c = [Math]::Round($chroma, 2)
            h = [Math]::Round($hue, 2)
        }
    } -Force

    # Convert LCH to LAB
    Set-Item -Path Function:Global:_Convert-LchToLab -Value {
        param(
            [double]$L,
            [double]$C,
            [double]$H
        )
        
        $hueRadians = $H * [Math]::PI / 180.0
        $a = $C * [Math]::Cos($hueRadians)
        $b = $C * [Math]::Sin($hueRadians)
        
        return @{
            l = [Math]::Round($L, 2)
            a = [Math]::Round($a, 2)
            b = [Math]::Round($b, 2)
        }
    } -Force

    # Convert RGB to LCH
    Set-Item -Path Function:Global:_Convert-RgbToLch -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
        
        $lab = _Convert-RgbToLab -Red $Red -Green $Green -Blue $Blue
        return _Convert-LabToLch -L $lab.l -A $lab.a -B $lab.b
    } -Force

    # Convert LCH to RGB
    Set-Item -Path Function:Global:_Convert-LchToRgb -Value {
        param(
            [double]$L,
            [double]$C,
            [double]$H
        )
        
        $lab = _Convert-LchToLab -L $L -C $C -H $H
        return _Convert-LabToRgb -L $lab.l -A $lab.a -B $lab.b
    } -Force
}

