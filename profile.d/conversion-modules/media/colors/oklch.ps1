# ===============================================
# OKLCH/OKLCHa Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes OKLCH/OKLCHa color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for OKLCH/OKLCHa (Lightness, Chroma, Hue) color format conversions.
    Supports converting between OKLCH and RGB via OKLAB intermediate color space.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    OKLCH conversions follow CSS Color Module Level 4 specifications.
    OKLCH is an improved perceptually uniform color space derived from OKLAB.
    Uses sRGB color space.
#>
function Initialize-FileConversion-MediaColorsOklch {
    # Convert OKLAB to OKLCH
    Set-Item -Path Function:Global:_Convert-OklabToOklch -Value {
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
            l = [Math]::Round($L, 4)
            c = [Math]::Round($chroma, 4)
            h = [Math]::Round($hue, 4)
        }
    } -Force

    # Convert OKLCH to OKLAB
    Set-Item -Path Function:Global:_Convert-OklchToOklab -Value {
        param(
            [double]$L,
            [double]$C,
            [double]$H
        )
        
        $hueRadians = $H * [Math]::PI / 180.0
        $a = $C * [Math]::Cos($hueRadians)
        $b = $C * [Math]::Sin($hueRadians)
        
        return @{
            l = [Math]::Round($L, 4)
            a = [Math]::Round($a, 4)
            b = [Math]::Round($b, 4)
        }
    } -Force

    # Convert RGB to OKLCH
    Set-Item -Path Function:Global:_Convert-RgbToOklch -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
        
        $oklab = _Convert-RgbToOklab -Red $Red -Green $Green -Blue $Blue
        return _Convert-OklabToOklch -L $oklab.l -A $oklab.a -B $oklab.b
    } -Force

    # Convert OKLCH to RGB
    Set-Item -Path Function:Global:_Convert-OklchToRgb -Value {
        param(
            [double]$L,
            [double]$C,
            [double]$H
        )
        
        $oklab = _Convert-OklchToOklab -L $L -C $C -H $H
        return _Convert-OklabToRgb -L $oklab.l -A $oklab.a -B $oklab.b
    } -Force
}

