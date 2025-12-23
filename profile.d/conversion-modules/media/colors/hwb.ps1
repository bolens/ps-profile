# ===============================================
# HWB/HWBA Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes HWB/HWBA color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HWB/HWBA color format conversions.
    Supports converting between HWB and RGB.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    HWB conversions follow CSS Color Module Level 4 specifications.
#>
function Initialize-FileConversion-MediaColorsHwb {
    # Convert HWB to RGB
    Set-Item -Path Function:Global:_Convert-HwbToRgb -Value {
        param(
            [double]$Hue,
            [double]$Whiteness,
            [double]$Blackness
        )
        
        $hueNormalized = $Hue / 360.0
        $whitenessNormalized = [Math]::Max(0, [Math]::Min(1, $Whiteness))
        $blacknessNormalized = [Math]::Max(0, [Math]::Min(1, $Blackness))
        
        if ($whitenessNormalized + $blacknessNormalized -ge 1) {
            $grayRatio = $whitenessNormalized / ($whitenessNormalized + $blacknessNormalized)
            $grayValue = [Math]::Round($grayRatio * 255)
            return @{ r = $grayValue; g = $grayValue; b = $grayValue }
        }
        
        # Convert HWB to RGB: start with pure hue (HSL with s=1, l=0.5), then mix with white and black
        $pureRgb = _Convert-HslToRgb -Hue ($hueNormalized * 360) -Saturation 1.0 -Lightness 0.5
        
        # Mix with white (add whiteness)
        $redComponent = $pureRgb.r + ($whitenessNormalized * (255 - $pureRgb.r))
        $greenComponent = $pureRgb.g + ($whitenessNormalized * (255 - $pureRgb.g))
        $blueComponent = $pureRgb.b + ($whitenessNormalized * (255 - $pureRgb.b))
        
        # Mix with black (subtract blackness)
        $redComponent = $redComponent * (1 - $blacknessNormalized)
        $greenComponent = $greenComponent * (1 - $blacknessNormalized)
        $blueComponent = $blueComponent * (1 - $blacknessNormalized)
        
        return @{
            r = [Math]::Round($redComponent)
            g = [Math]::Round($greenComponent)
            b = [Math]::Round($blueComponent)
        }
    } -Force

    # Convert RGB to HWB
    Set-Item -Path Function:Global:_Convert-RgbToHwb -Value {
        param(
            [int]$Red,
            [int]$Green,
            [int]$Blue
        )
        
        $redNormalized = $Red / 255.0
        $greenNormalized = $Green / 255.0
        $blueNormalized = $Blue / 255.0
        
        $maxComponent = [Math]::Max($redNormalized, [Math]::Max($greenNormalized, $blueNormalized))
        $minComponent = [Math]::Min($redNormalized, [Math]::Min($greenNormalized, $blueNormalized))
        $delta = $maxComponent - $minComponent
        
        $whiteness = $minComponent
        $blackness = 1 - $maxComponent
        
        $hue = 0
        if ($delta -ne 0) {
            if ($maxComponent -eq $redNormalized) {
                $hue = (($greenNormalized - $blueNormalized) / $delta) % 6
            }
            elseif ($maxComponent -eq $greenNormalized) {
                $hue = ($blueNormalized - $redNormalized) / $delta + 2
            }
            else {
                $hue = ($redNormalized - $greenNormalized) / $delta + 4
            }
            
            $hue = $hue * 60
            if ($hue -lt 0) { $hue += 360 }
        }
        
        return @{
            h = [Math]::Round($hue, 2)
            w = [Math]::Round($whiteness * 100, 2)
            b = [Math]::Round($blackness * 100, 2)
        }
    } -Force
}

