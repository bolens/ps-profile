# ===============================================
# Color Parsing Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes color parsing utility functions.
.DESCRIPTION
    Sets up the main color parsing function that routes to format-specific parsers.
    Supports parsing RGB, RGBA, HEX, HSL, HSLA, HWB, HWBA, CMYK, CMYKA, NCOL, NCOLA, LAB, LABa, OKLAB, OKLABa, LCH, LCHa, OKLCH, OKLCHa, and named colors.
    This function is called automatically by Initialize-FileConversion-MediaColors.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaColorsParse {
    # Parse color string to RGB/RGBA object
    Set-Item -Path Function:Global:_Parse-Color -Value {
        param([string]$ColorString)
        
        if ([string]::IsNullOrWhiteSpace($ColorString)) {
            throw "Color string cannot be empty"
        }
        
        $colorString = $ColorString.Trim()
        
        # Check for named color
        $colorName = $colorString.ToLower()
        if ($script:CssNamedColors.ContainsKey($colorName)) {
            return $script:CssNamedColors[$colorName].Clone()
        }
        
        # Parse HEX (#rgb, #rrggbb, #rrggbbaa)
        if ($colorString -match '^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$') {
            $hex = $matches[1]
            if ($hex.Length -eq 3) {
                # Expand shorthand #rgb to #rrggbb
                $hex = $hex[0] + $hex[0] + $hex[1] + $hex[1] + $hex[2] + $hex[2]
            }
            if ($hex.Length -eq 6) {
                return @{
                    r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
                    g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
                    b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
                }
            }
            if ($hex.Length -eq 8) {
                return @{
                    r = [Convert]::ToInt32($hex.Substring(0, 2), 16)
                    g = [Convert]::ToInt32($hex.Substring(2, 2), 16)
                    b = [Convert]::ToInt32($hex.Substring(4, 2), 16)
                    a = [Convert]::ToInt32($hex.Substring(6, 2), 16) / 255.0
                }
            }
        }
        
        # Parse RGB/RGBA
        if ($colorString -match '^rgba?\s*\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*(?:,\s*(-?[\d.]+))?\s*\)$') {
            $r = [Math]::Min(255, [Math]::Max(0, [int][double]$matches[1]))
            $g = [Math]::Min(255, [Math]::Max(0, [int][double]$matches[2]))
            $b = [Math]::Min(255, [Math]::Max(0, [int][double]$matches[3]))
            $result = @{ r = $r; g = $g; b = $b }
            if ($matches[4]) {
                $a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
                $result.a = $a
            }
            return $result
        }
        
        # Parse RGB/RGBA with percentage values
        if ($colorString -match '^rgba?\s*\(\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*([\d.]+))?\s*\)$') {
            $r = [Math]::Min(255, [Math]::Max(0, [int]([double]$matches[1] * 2.55)))
            $g = [Math]::Min(255, [Math]::Max(0, [int]([double]$matches[2] * 2.55)))
            $b = [Math]::Min(255, [Math]::Max(0, [int]([double]$matches[3] * 2.55)))
            $result = @{ r = $r; g = $g; b = $b }
            if ($matches[4]) {
                $a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
                $result.a = $a
            }
            return $result
        }
        
        # Parse HSL
        if ($colorString -match '^hsla?\s*\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*(-?[\d.]+))?\s*\)$') {
            $h = [double]$matches[1]
            # Handle negative hue by adding 360 until positive
            while ($h -lt 0) { $h += 360 }
            $h = $h % 360
            $s = [Math]::Min(100, [Math]::Max(0, [double]$matches[2])) / 100.0
            $l = [Math]::Min(100, [Math]::Max(0, [double]$matches[3])) / 100.0
            $rgb = _Convert-HslToRgb -Hue $h -Saturation $s -Lightness $l
            if ($matches[4]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
            }
            return $rgb
        }
        
        # Parse HWB
        if ($colorString -match '^hwba?\s*\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*([\d.]+))?\s*\)$') {
            $h = [double]$matches[1] % 360
            $w = [Math]::Min(100, [Math]::Max(0, [double]$matches[2])) / 100.0
            $b = [Math]::Min(100, [Math]::Max(0, [double]$matches[3])) / 100.0
            $rgb = _Convert-HwbToRgb -Hue $h -Whiteness $w -Blackness $b
            if ($matches[4]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
            }
            return $rgb
        }
        
        # Parse CMYK
        if ($colorString -match '^cmyka?\s*\(\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*([\d.]+))?\s*\)$') {
            $c = [Math]::Min(100, [Math]::Max(0, [double]$matches[1])) / 100.0
            $m = [Math]::Min(100, [Math]::Max(0, [double]$matches[2])) / 100.0
            $y = [Math]::Min(100, [Math]::Max(0, [double]$matches[3])) / 100.0
            $k = [Math]::Min(100, [Math]::Max(0, [double]$matches[4])) / 100.0
            $rgb = _Convert-CmykToRgb -Cyan $c -Magenta $m -Yellow $y -Key $k
            if ($matches[5]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[5]))
            }
            return $rgb
        }
        
        # Parse NCOL (Natural Color System)
        if ($colorString -match '^ncola?\s*\(\s*([RYGB]\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*([\d.]+))?\s*\)$') {
            $hue = $matches[1]
            $blackness = [Math]::Min(100, [Math]::Max(0, [double]$matches[2])) / 100.0
            $whiteness = [Math]::Min(100, [Math]::Max(0, [double]$matches[3])) / 100.0
            $rgb = _Convert-NcolToRgb -Hue $hue -Blackness $blackness -Whiteness $whiteness
            if ($matches[4]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
            }
            return $rgb
        }
        
        # Parse LAB/LABa (space-separated, optional alpha with /)
        if ($colorString -match '^laba?\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s*(?:\s*/\s*([\d.]+))?\s*\)$') {
            $l = [double]$matches[1]
            $a = [double]$matches[2]
            $b = [double]$matches[3]
            $rgb = _Convert-LabToRgb -L $l -A $a -B $b
            if ($matches[4]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
            }
            return $rgb
        }
        
        # Parse OKLAB/OKLABa (space-separated, optional alpha with /)
        if ($colorString -match '^oklaba?\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s*(?:\s*/\s*([\d.]+))?\s*\)$') {
            $l = [double]$matches[1]
            $a = [double]$matches[2]
            $b = [double]$matches[3]
            $rgb = _Convert-OklabToRgb -L $l -A $a -B $b
            if ($matches[4]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
            }
            return $rgb
        }
        
        # Parse LCH/LCHa (space-separated, optional alpha with /)
        if ($colorString -match '^lcha?\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s*(?:\s*/\s*([\d.]+))?\s*\)$') {
            $l = [double]$matches[1]
            $c = [Math]::Max(0, [double]$matches[2])
            $h = [double]$matches[3]
            # Normalize hue to 0-360
            while ($h -lt 0) { $h += 360 }
            $h = $h % 360
            $rgb = _Convert-LchToRgb -L $l -C $c -H $h
            if ($matches[4]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
            }
            return $rgb
        }
        
        # Parse OKLCH/OKLCHa (space-separated, optional alpha with /)
        if ($colorString -match '^oklcha?\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s*(?:\s*/\s*([\d.]+))?\s*\)$') {
            $l = [double]$matches[1]
            $c = [Math]::Max(0, [double]$matches[2])
            $h = [double]$matches[3]
            # Normalize hue to 0-360
            while ($h -lt 0) { $h += 360 }
            $h = $h % 360
            $rgb = _Convert-OklchToRgb -L $l -C $c -H $h
            if ($matches[4]) {
                $rgb.a = [Math]::Min(1.0, [Math]::Max(0.0, [double]$matches[4]))
            }
            return $rgb
        }
        
        throw "Unable to parse color string: $ColorString"
    } -Force
}

