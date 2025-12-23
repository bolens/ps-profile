# ===============================================
# OKLAB/OKLABa Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes OKLAB/OKLABa color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for OKLAB/OKLABa color format conversions.
    Supports converting between OKLAB and RGB via linear RGB intermediate color space.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    OKLAB conversions follow CSS Color Module Level 4 specifications.
    OKLAB is an improved perceptually uniform color space, better than traditional LAB.
    Uses sRGB color space.
#>
function Initialize-FileConversion-MediaColorsOklab {
    # Convert RGB to OKLAB
    Set-Item -Path Function:Global:_Convert-RgbToOklab -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
        
        # Convert to linear RGB (reuse existing helper)
        $rLinear = _Convert-RgbToLinearRgb -Component $Red
        $gLinear = _Convert-RgbToLinearRgb -Component $Green
        $bLinear = _Convert-RgbToLinearRgb -Component $Blue
        
        # Convert linear RGB to OKLAB (via LMS cone response)
        # Step 1: Linear RGB to LMS
        $l = 0.4122214708 * $rLinear + 0.5363325363 * $gLinear + 0.0514459929 * $bLinear
        $m = 0.2119034982 * $rLinear + 0.6806995451 * $gLinear + 0.1073969566 * $bLinear
        $s = 0.0883024619 * $rLinear + 0.2817188376 * $gLinear + 0.6299787005 * $bLinear
        
        # Step 2: Apply non-linearity (cube root)
        $lCbrt = [Math]::Pow($l, 1.0 / 3.0)
        $mCbrt = [Math]::Pow($m, 1.0 / 3.0)
        $sCbrt = [Math]::Pow($s, 1.0 / 3.0)
        
        # Step 3: LMS to OKLAB
        $lightness = 0.2104542553 * $lCbrt + 0.7936177850 * $mCbrt - 0.0040720468 * $sCbrt
        $a = 1.9779984951 * $lCbrt - 2.4285922050 * $mCbrt + 0.4505937099 * $sCbrt
        $b = 0.0259040371 * $lCbrt + 0.7827717662 * $mCbrt - 0.8086757660 * $sCbrt
        
        return @{
            l = [Math]::Round($lightness, 4)
            a = [Math]::Round($a, 4)
            b = [Math]::Round($b, 4)
        }
    } -Force

    # Convert OKLAB to RGB
    Set-Item -Path Function:Global:_Convert-OklabToRgb -Value {
        param(
            [double]$L,
            [double]$A,
            [double]$B
        )
        
        # Step 1: OKLAB to LMS
        $lCbrt = $L + 0.3963377774 * $A + 0.2158037573 * $B
        $mCbrt = $L - 0.1055613458 * $A - 0.0638541728 * $B
        $sCbrt = $L - 0.0894841775 * $A - 1.2914855480 * $B
        
        # Step 2: Apply non-linearity (cube)
        $l = $lCbrt * $lCbrt * $lCbrt
        $m = $mCbrt * $mCbrt * $mCbrt
        $s = $sCbrt * $sCbrt * $sCbrt
        
        # Step 3: LMS to linear RGB
        $rLinear = +4.0767416621 * $l - 3.3077115913 * $m + 0.2309699292 * $s
        $gLinear = -1.2684380046 * $l + 2.6097574011 * $m - 0.3413193965 * $s
        $bLinear = -0.0041960863 * $l - 0.7034186147 * $m + 1.7076147010 * $s
        
        # Step 4: Linear RGB to RGB (reuse existing helper)
        $red = _Convert-LinearRgbToRgb -Component $rLinear
        $green = _Convert-LinearRgbToRgb -Component $gLinear
        $blue = _Convert-LinearRgbToRgb -Component $bLinear
        
        return @{
            r = [Math]::Max(0, [Math]::Min(255, [Math]::Round($red)))
            g = [Math]::Max(0, [Math]::Min(255, [Math]::Round($green)))
            b = [Math]::Max(0, [Math]::Min(255, [Math]::Round($blue)))
        }
    } -Force
}

