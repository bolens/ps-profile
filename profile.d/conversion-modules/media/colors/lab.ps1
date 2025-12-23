# ===============================================
# LAB/LABa Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes LAB/LABa color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for LAB/LABa (CIE LAB) color format conversions.
    Supports converting between LAB and RGB via XYZ intermediate color space.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    LAB conversions follow CSS Color Module Level 4 specifications.
    LAB is a device-independent color space based on human vision.
    Uses D65 white point and sRGB color space.
#>
function Initialize-FileConversion-MediaColorsLab {
    # Helper: Convert RGB to linear RGB (gamma correction)
    Set-Item -Path Function:Global:_Convert-RgbToLinearRgb -Value {
        param(
            [double]$Component
        )
        
        $normalized = $Component / 255.0
        if ($normalized -le 0.04045) {
            return $normalized / 12.92
        }
        else {
            return [Math]::Pow(($normalized + 0.055) / 1.055, 2.4)
        }
    } -Force

    # Helper: Convert linear RGB to RGB (gamma correction)
    Set-Item -Path Function:Global:_Convert-LinearRgbToRgb -Value {
        param(
            [double]$Component
        )
        
        if ($Component -le 0.0031308) {
            return $Component * 12.92 * 255.0
        }
        else {
            return (1.055 * [Math]::Pow($Component, 1.0 / 2.4) - 0.055) * 255.0
        }
    } -Force

    # Convert RGB to XYZ (D65 white point, sRGB)
    Set-Item -Path Function:Global:_Convert-RgbToXyz -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
        
        # Convert to linear RGB
        $rLinear = _Convert-RgbToLinearRgb -Component $Red
        $gLinear = _Convert-RgbToLinearRgb -Component $Green
        $bLinear = _Convert-RgbToLinearRgb -Component $Blue
        
        # Convert linear RGB to XYZ (sRGB to XYZ matrix, D65 white point)
        $x = 0.4124564 * $rLinear + 0.3575761 * $gLinear + 0.1804375 * $bLinear
        $y = 0.2126729 * $rLinear + 0.7151522 * $gLinear + 0.0721750 * $bLinear
        $z = 0.0193339 * $rLinear + 0.1191920 * $gLinear + 0.9503041 * $bLinear
        
        return @{
            x = $x
            y = $y
            z = $z
        }
    } -Force

    # Convert XYZ to RGB (D65 white point, sRGB)
    Set-Item -Path Function:Global:_Convert-XyzToRgb -Value {
        param(
            [double]$X,
            [double]$Y,
            [double]$Z
        )
        
        # Convert XYZ to linear RGB (XYZ to sRGB matrix, D65 white point)
        $rLinear = 3.2404542 * $X - 1.5371385 * $Y - 0.4985314 * $Z
        $gLinear = -0.9692660 * $X + 1.8760108 * $Y + 0.0415560 * $Z
        $bLinear = 0.0556434 * $X - 0.2040259 * $Y + 1.0572252 * $Z
        
        # Convert linear RGB to RGB
        $red = _Convert-LinearRgbToRgb -Component $rLinear
        $green = _Convert-LinearRgbToRgb -Component $gLinear
        $blue = _Convert-LinearRgbToRgb -Component $bLinear
        
        return @{
            r = [Math]::Max(0, [Math]::Min(255, [Math]::Round($red)))
            g = [Math]::Max(0, [Math]::Min(255, [Math]::Round($green)))
            b = [Math]::Max(0, [Math]::Min(255, [Math]::Round($blue)))
        }
    } -Force

    # Convert XYZ to LAB (D65 white point)
    Set-Item -Path Function:Global:_Convert-XyzToLab -Value {
        param(
            [double]$X,
            [double]$Y,
            [double]$Z
        )
        
        # D65 white point (sRGB)
        $xn = 0.95047
        $yn = 1.00000
        $zn = 1.08883
        
        # Normalize by white point
        $x = $X / $xn
        $y = $Y / $yn
        $z = $Z / $zn
        
        # Apply f function
        $fx = if ($x -gt 0.008856) { [Math]::Pow($x, 1.0 / 3.0) } else { (7.787 * $x) + (16.0 / 116.0) }
        $fy = if ($y -gt 0.008856) { [Math]::Pow($y, 1.0 / 3.0) } else { (7.787 * $y) + (16.0 / 116.0) }
        $fz = if ($z -gt 0.008856) { [Math]::Pow($z, 1.0 / 3.0) } else { (7.787 * $z) + (16.0 / 116.0) }
        
        $lightness = (116.0 * $fy) - 16.0
        $a = 500.0 * ($fx - $fy)
        $b = 200.0 * ($fy - $fz)
        
        return @{
            l = [Math]::Round($lightness, 2)
            a = [Math]::Round($a, 2)
            b = [Math]::Round($b, 2)
        }
    } -Force

    # Convert LAB to XYZ (D65 white point)
    Set-Item -Path Function:Global:_Convert-LabToXyz -Value {
        param(
            [double]$L,
            [double]$A,
            [double]$B
        )
        
        # D65 white point (sRGB)
        $xn = 0.95047
        $yn = 1.00000
        $zn = 1.08883
        
        $fy = ($L + 16.0) / 116.0
        $fx = $A / 500.0 + $fy
        $fz = $fy - $B / 200.0
        
        # Convert f to x, y, z
        $x = if ($fx -gt 0.206897) { [Math]::Pow($fx, 3.0) } else { ($fx - 16.0 / 116.0) / 7.787 }
        $y = if ($fy -gt 0.206897) { [Math]::Pow($fy, 3.0) } else { ($fy - 16.0 / 116.0) / 7.787 }
        $z = if ($fz -gt 0.206897) { [Math]::Pow($fz, 3.0) } else { ($fz - 16.0 / 116.0) / 7.787 }
        
        return @{
            x = $x * $xn
            y = $y * $yn
            z = $z * $zn
        }
    } -Force

    # Convert RGB to LAB
    Set-Item -Path Function:Global:_Convert-RgbToLab -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
        
        $xyz = _Convert-RgbToXyz -Red $Red -Green $Green -Blue $Blue
        return _Convert-XyzToLab -X $xyz.x -Y $xyz.y -Z $xyz.z
    } -Force

    # Convert LAB to RGB
    Set-Item -Path Function:Global:_Convert-LabToRgb -Value {
        param(
            [double]$L,
            [double]$A,
            [double]$B
        )
        
        $xyz = _Convert-LabToXyz -L $L -A $A -B $B
        return _Convert-XyzToRgb -X $xyz.x -Y $xyz.y -Z $xyz.z
    } -Force
}

