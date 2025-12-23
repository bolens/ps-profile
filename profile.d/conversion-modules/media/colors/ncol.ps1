# ===============================================
# NCOL/NCOLA Color Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes NCOL/NCOLA color conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for NCOL/NCOLA (Natural Color System) color format conversions.
    Supports converting between NCOL and RGB.
    This function is called automatically by Initialize-FileConversion-MediaColors.
.NOTES
    This is an internal initialization function and should not be called directly.
    NCOL uses base colors R (Red), Y (Yellow), G (Green), B (Blue) with hue values 0-100.
#>
function Initialize-FileConversion-MediaColorsNcol {
    # Convert NCOL to RGB
    Set-Item -Path Function:Global:_Convert-NcolToRgb -Value {
        param(
            [string]$Hue,
            [double]$Blackness,
            [double]$Whiteness
        )
        
        # NCOL hue format: R0, Y0, G0, B0, etc. (0-100)
        if ($Hue -notmatch '^([RYGB])(\d+(?:\.\d+)?)$') {
            throw "Invalid NCOL hue format: $Hue"
        }
        
        $baseColor = $matches[1]
        $hueValue = [double]$matches[2]
        
        # Map NCOL base colors to HSL hue values
        $baseHues = @{
            'R' = 0    # Red
            'Y' = 60   # Yellow
            'G' = 120  # Green
            'B' = 240  # Blue
        }
        
        $baseHue = $baseHues[$baseColor]
        $h = ($baseHue + ($hueValue * 0.6)) % 360  # NCOL uses 0-100 scale, map to 0-60 degrees
        
        $b = [Math]::Max(0, [Math]::Min(1, $Blackness))
        $w = [Math]::Max(0, [Math]::Min(1, $Whiteness))
        
        # Convert NCOL to HWB (they're similar)
        $rgb = _Convert-HwbToRgb -Hue $h -Whiteness $w -Blackness $b
        
        return $rgb
    } -Force
}

