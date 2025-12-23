# ===============================================
# Color Conversion Routing and Public Functions
# ===============================================

<#
.SYNOPSIS
    Initializes color conversion routing and public functions.
.DESCRIPTION
    Sets up the main color conversion routing function and public-facing functions.
    Supports converting between all color formats.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaColorsConvert {
    # Main conversion function
    Set-Item -Path Function:Global:_Convert-ColorFormat -Value {
        param(
            [string]$Color,
            [ValidateSet('rgb', 'rgba', 'hex', 'hsl', 'hsla', 'hwb', 'hwba', 'cmyk', 'cmyka', 'ncol', 'ncola', 'lab', 'laba', 'oklab', 'oklaba', 'lch', 'lcha', 'oklch', 'oklcha', 'name')]
            [string]$ToFormat
        )
        
        $rgb = _Parse-Color -ColorString $Color
        
        switch ($ToFormat.ToLower()) {
            'rgb' {
                return "rgb($($rgb.r), $($rgb.g), $($rgb.b))"
            }
            'rgba' {
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "rgba($($rgb.r), $($rgb.g), $($rgb.b), $a)"
            }
            'hex' {
                $includeAlpha = $rgb.ContainsKey('a') -and $rgb.a -lt 1.0
                $alpha = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return _Convert-RgbToHex -Red $rgb.r -Green $rgb.g -Blue $rgb.b -IncludeAlpha:$includeAlpha -Alpha $alpha
            }
            'hsl' {
                $hsl = _Convert-RgbToHsl -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                return "hsl($($hsl.h), $($hsl.s)%, $($hsl.l)%)"
            }
            'hsla' {
                $hsl = _Convert-RgbToHsl -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "hsla($($hsl.h), $($hsl.s)%, $($hsl.l)%, $a)"
            }
            'hwb' {
                $hwb = _Convert-RgbToHwb -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                return "hwb($($hwb.h), $($hwb.w)%, $($hwb.b)%)"
            }
            'hwba' {
                $hwb = _Convert-RgbToHwb -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "hwba($($hwb.h), $($hwb.w)%, $($hwb.b)%, $a)"
            }
            'cmyk' {
                $cmyk = _Convert-RgbToCmyk -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                return "cmyk($($cmyk.c)%, $($cmyk.m)%, $($cmyk.y)%, $($cmyk.k)%)"
            }
            'cmyka' {
                $cmyk = _Convert-RgbToCmyk -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "cmyka($($cmyk.c)%, $($cmyk.m)%, $($cmyk.y)%, $($cmyk.k)%, $a)"
            }
            'ncol' {
                $hwb = _Convert-RgbToHwb -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                # Convert HWB hue to NCOL format (approximate)
                $hueDeg = $hwb.h
                $ncolHue = if ($hueDeg -lt 30) { "R$([Math]::Round($hueDeg / 0.6))" }
                elseif ($hueDeg -lt 90) { "Y$([Math]::Round(($hueDeg - 60) / 0.6))" }
                elseif ($hueDeg -lt 150) { "G$([Math]::Round(($hueDeg - 120) / 0.6))" }
                else { "B$([Math]::Round(($hueDeg - 240) / 0.6))" }
                return "ncol($ncolHue, $($hwb.w)%, $($hwb.b)%)"
            }
            'ncola' {
                $hwb = _Convert-RgbToHwb -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $hueDeg = $hwb.h
                $ncolHue = if ($hueDeg -lt 30) { "R$([Math]::Round($hueDeg / 0.6))" }
                elseif ($hueDeg -lt 90) { "Y$([Math]::Round(($hueDeg - 60) / 0.6))" }
                elseif ($hueDeg -lt 150) { "G$([Math]::Round(($hueDeg - 120) / 0.6))" }
                else { "B$([Math]::Round(($hueDeg - 240) / 0.6))" }
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "ncola($ncolHue, $($hwb.w)%, $($hwb.b)%, $a)"
            }
            'lab' {
                $lab = _Convert-RgbToLab -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                return "lab($($lab.l) $($lab.a) $($lab.b))"
            }
            'laba' {
                $lab = _Convert-RgbToLab -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "laba($($lab.l) $($lab.a) $($lab.b) / $a)"
            }
            'oklab' {
                $oklab = _Convert-RgbToOklab -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                return "oklab($($oklab.l) $($oklab.a) $($oklab.b))"
            }
            'oklaba' {
                $oklab = _Convert-RgbToOklab -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "oklaba($($oklab.l) $($oklab.a) $($oklab.b) / $a)"
            }
            'lch' {
                $lch = _Convert-RgbToLch -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                return "lch($($lch.l) $($lch.c) $($lch.h))"
            }
            'lcha' {
                $lch = _Convert-RgbToLch -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "lcha($($lch.l) $($lch.c) $($lch.h) / $a)"
            }
            'oklch' {
                $oklch = _Convert-RgbToOklch -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                return "oklch($($oklch.l) $($oklch.c) $($oklch.h))"
            }
            'oklcha' {
                $oklch = _Convert-RgbToOklch -Red $rgb.r -Green $rgb.g -Blue $rgb.b
                $a = if ($rgb.ContainsKey('a')) { $rgb.a } else { 1.0 }
                return "oklcha($($oklch.l) $($oklch.c) $($oklch.h) / $a)"
            }
            'name' {
                # Try to find closest named color
                $minDistance = [double]::MaxValue
                $closestName = 'black'
                    
                foreach ($name in $script:CssNamedColors.Keys) {
                    if ($name -eq 'transparent') { continue }
                    $namedRgb = $script:CssNamedColors[$name]
                    $distance = [Math]::Sqrt(
                        [Math]::Pow($rgb.r - $namedRgb.r, 2) +
                        [Math]::Pow($rgb.g - $namedRgb.g, 2) +
                        [Math]::Pow($rgb.b - $namedRgb.b, 2)
                    )
                    if ($distance -lt $minDistance) {
                        $minDistance = $distance
                        $closestName = $name
                    }
                }
                    
                # If exact match, return it
                if ($minDistance -eq 0) {
                    return $closestName
                }
                    
                # Otherwise return the closest approximation
                return $closestName
            }
        }
    } -Force

    # Public functions and aliases
    Set-Item -Path Function:Global:Convert-Color -Value {
        <#
        .SYNOPSIS
            Converts a color from one format to another.
        .DESCRIPTION
            Converts colors between RGB, RGBA, HEX, HSL, HSLA, HWB, HWBA, CMYK, CMYKA, NCOL, NCOLA, LAB, LABa, OKLAB, OKLABa, LCH, LCHa, OKLCH, OKLCHa, and named color formats.
            Supports parsing colors in any of these formats and converting to any other format.
        .PARAMETER Color
            The color string to convert. Can be in any supported format (RGB, RGBA, HEX, HSL, HSLA, HWB, HWBA, CMYK, CMYKA, NCOL, NCOLA, LAB, LABa, OKLAB, OKLABa, LCH, LCHa, OKLCH, OKLCHa, or named color).
        .PARAMETER ToFormat
            The target format for conversion. Valid values: rgb, rgba, hex, hsl, hsla, hwb, hwba, cmyk, cmyka, ncol, ncola, lab, laba, oklab, oklaba, lch, lcha, oklch, oklcha, name.
        .EXAMPLE
            Convert-Color -Color "#ff0000" -ToFormat "rgb"
            
            Converts the hex color #ff0000 to RGB format.
        .EXAMPLE
            Convert-Color -Color "rgb(255, 0, 0)" -ToFormat "hsl"
            
            Converts RGB red to HSL format.
        .EXAMPLE
            Convert-Color -Color "red" -ToFormat "hex"
            
            Converts the named color "red" to hex format.
        .OUTPUTS
            System.String
            Returns the color in the specified format.
        #>
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [string]$Color,
            [Parameter(Mandatory)]
            [ValidateSet('rgb', 'rgba', 'hex', 'hsl', 'hsla', 'hwb', 'hwba', 'cmyk', 'cmyka', 'ncol', 'ncola', 'lab', 'laba', 'oklab', 'oklaba', 'lch', 'lcha', 'oklch', 'oklcha', 'name')]
            [string]$ToFormat
        )
        
        if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
        try {
            _Convert-ColorFormat -Color $Color -ToFormat $ToFormat
        }
        catch {
            throw "Failed to convert color: $($_.Exception.Message)"
        }
    } -Force
    Set-Alias -Name color-convert -Value Convert-Color -ErrorAction SilentlyContinue -Scope Global

    Set-Item -Path Function:Global:Parse-Color -Value {
        <#
        .SYNOPSIS
            Parses a color string and returns RGB/RGBA values.
        .DESCRIPTION
            Parses a color string in any supported format and returns an object with r, g, b, and optionally a (alpha) properties.
        .PARAMETER Color
            The color string to parse. Can be in any supported format.
        .EXAMPLE
            Parse-Color -Color "#ff0000"
            
            Returns an object with r=255, g=0, b=0.
        .EXAMPLE
            Parse-Color -Color "rgba(255, 0, 0, 0.5)"
            
            Returns an object with r=255, g=0, b=0, a=0.5.
        .OUTPUTS
            System.Collections.Hashtable
            Returns a hashtable with r, g, b, and optionally a properties.
        #>
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [string]$Color
        )
        
        if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
        try {
            _Parse-Color -ColorString $Color
        }
        catch {
            throw "Failed to parse color: $($_.Exception.Message)"
        }
    } -Force
    Set-Alias -Name color-parse -Value Parse-Color -ErrorAction SilentlyContinue -Scope Global
}

