# ===============================================
# HSL/HSLA Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes HSL/HSLA color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for HSL/HSLA color format conversions.
    Supports parsing HSL/HSLA strings and converting between HSL and RGB.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
    HSL conversions follow CSS Color Module Level 4 specifications.
#>
function Initialize-FileConversion-MediaColorsHsl {
    # Convert HSL to RGB
    Set-Item -Path Function:Global:_Convert-HslToRgb -Value {
        param(
            [double]$Hue,
            [double]$Saturation,
            [double]$Lightness
        )
        
        # Calculate normalized values step by step (breaking nested calls to avoid PowerShell parsing issues)
        $hueNormalized = $Hue / 360.0
        
        # For saturation and lightness, calculate Min first, then Max
        $satMin = [Math]::Min(1.0, $Saturation)
        $saturationNormalized = [Math]::Max(0.0, $satMin)
        
        $lightMin = [Math]::Min(1.0, $Lightness)
        $lightnessNormalized = [Math]::Max(0.0, $lightMin)
        
        if ($saturationNormalized -eq 0) {
            $grayValue = [Math]::Round($lightnessNormalized * 255)
            return @{ r = $grayValue; g = $grayValue; b = $grayValue }
        }
        
        # Calculate chroma and intermediate values
        $chroma = (1.0 - [Math]::Abs(2.0 * $lightnessNormalized - 1.0)) * $saturationNormalized
        $hueTimes6 = $hueNormalized * 6.0
        $hueMod2 = $hueTimes6 - [Math]::Floor($hueTimes6 / 2.0) * 2.0
        $intermediateX = $chroma * (1.0 - [Math]::Abs($hueMod2 - 1.0))
        $meanValue = $lightnessNormalized - ($chroma / 2.0)
        
        # Determine RGB based on hue sector (using if/elseif for reliability)
        $hueSector = [int]([Math]::Floor($hueTimes6)) % 6
        $redComponent = 0.0
        $greenComponent = 0.0
        $blueComponent = 0.0
        
        if ($hueSector -eq 0) {
            $redComponent = $chroma; $greenComponent = $intermediateX; $blueComponent = 0.0
        }
        elseif ($hueSector -eq 1) {
            $redComponent = $intermediateX; $greenComponent = $chroma; $blueComponent = 0.0
        }
        elseif ($hueSector -eq 2) {
            $redComponent = 0.0; $greenComponent = $chroma; $blueComponent = $intermediateX
        }
        elseif ($hueSector -eq 3) {
            $redComponent = 0.0; $greenComponent = $intermediateX; $blueComponent = $chroma
        }
        elseif ($hueSector -eq 4) {
            $redComponent = $intermediateX; $greenComponent = 0.0; $blueComponent = $chroma
        }
        elseif ($hueSector -eq 5) {
            $redComponent = $chroma; $greenComponent = 0.0; $blueComponent = $intermediateX
        }
        
        # Add mean value to each component
        $redComponent = $redComponent + $meanValue
        $greenComponent = $greenComponent + $meanValue
        $blueComponent = $blueComponent + $meanValue
        
        # Create and return result hashtable
        $result = @{
            r = [Math]::Max(0, [Math]::Min(255, [Math]::Round($redComponent * 255.0)))
            g = [Math]::Max(0, [Math]::Min(255, [Math]::Round($greenComponent * 255.0)))
            b = [Math]::Max(0, [Math]::Min(255, [Math]::Round($blueComponent * 255.0)))
        }
        return $result
    } -Force

    # Convert RGB to HSL
    Set-Item -Path Function:Global:_Convert-RgbToHsl -Value {
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
        
        $lightness = ($maxComponent + $minComponent) / 2.0
        $saturation = 0
        $hue = 0
        
        if ($delta -ne 0) {
            $saturation = if ($lightness -lt 0.5) { $delta / ($maxComponent + $minComponent) } else { $delta / (2 - $maxComponent - $minComponent) }
                
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
            s = [Math]::Round($saturation * 100, 2)
            l = [Math]::Round($lightness * 100, 2)
        }
    } -Force
}

