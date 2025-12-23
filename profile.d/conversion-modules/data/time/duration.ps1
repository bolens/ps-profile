# ===============================================
# Duration/TimeSpan conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Duration/TimeSpan conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for duration/time span conversions.
    Supports conversions between human-readable durations and TimeSpan objects, seconds, milliseconds, etc.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Supports duration expressions like "2 hours", "30 minutes", "1 day 3 hours", etc.
#>
function Initialize-FileConversion-CoreTimeDuration {
    # Human-readable duration to TimeSpan
    Set-Item -Path Function:Global:_ConvertFrom-DurationToTimeSpan -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$DurationString
        )
        process {
            try {
                $input = $DurationString.Trim().ToLower()
                $totalSeconds = 0
                
                # Parse patterns like "2 hours 30 minutes", "1 day 3 hours 15 minutes", etc.
                $patterns = @(
                    @{ Pattern = '(\d+)\s*(?:year|years)'; Multiplier = 365 * 24 * 3600 }
                    @{ Pattern = '(\d+)\s*(?:month|months)'; Multiplier = 30 * 24 * 3600 }
                    @{ Pattern = '(\d+)\s*(?:week|weeks)'; Multiplier = 7 * 24 * 3600 }
                    @{ Pattern = '(\d+)\s*(?:day|days)'; Multiplier = 24 * 3600 }
                    @{ Pattern = '(\d+)\s*(?:hour|hours|hr|hrs)'; Multiplier = 3600 }
                    @{ Pattern = '(\d+)\s*(?:minute|minutes|min|mins)'; Multiplier = 60 }
                    @{ Pattern = '(\d+)\s*(?:second|seconds|sec|secs)'; Multiplier = 1 }
                    @{ Pattern = '(\d+)\s*(?:millisecond|milliseconds|ms)'; Multiplier = 0.001 }
                )
                
                foreach ($pattern in $patterns) {
                    if ($input -match $pattern.Pattern) {
                        $matches = [regex]::Matches($input, $pattern.Pattern)
                        foreach ($match in $matches) {
                            $value = [double]$match.Groups[1].Value
                            $totalSeconds += $value * $pattern.Multiplier
                        }
                    }
                }
                
                if ($totalSeconds -eq 0) {
                    # Try parsing as simple number (assume seconds)
                    if ($input -match '^\d+(\.\d+)?$') {
                        $totalSeconds = [double]$input
                    }
                    else {
                        throw "Could not parse duration: $DurationString"
                    }
                }
                
                return [TimeSpan]::FromSeconds($totalSeconds)
            }
            catch {
                throw "Failed to convert duration to TimeSpan: $_"
            }
        }
    } -Force

    # TimeSpan to Human-readable duration
    Set-Item -Path Function:Global:_ConvertTo-DurationFromTimeSpan -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [TimeSpan]$TimeSpan,
            [string]$Format = 'long'
        )
        process {
            try {
                $parts = @()
                $totalSeconds = $TimeSpan.TotalSeconds
                
                if ($Format -eq 'long') {
                    # Long format: "2 days 3 hours 15 minutes"
                    $days = [Math]::Floor($TimeSpan.TotalDays)
                    $hours = $TimeSpan.Hours
                    $minutes = $TimeSpan.Minutes
                    $seconds = $TimeSpan.Seconds
                    $milliseconds = $TimeSpan.Milliseconds
                    
                    if ($days -gt 0) { $parts += "$days day$(if ($days -ne 1) { 's' })" }
                    if ($hours -gt 0) { $parts += "$hours hour$(if ($hours -ne 1) { 's' })" }
                    if ($minutes -gt 0) { $parts += "$minutes minute$(if ($minutes -ne 1) { 's' })" }
                    if ($seconds -gt 0 -and $days -eq 0 -and $hours -eq 0) { $parts += "$seconds second$(if ($seconds -ne 1) { 's' })" }
                    if ($milliseconds -gt 0 -and $totalSeconds -lt 1) { $parts += "$milliseconds millisecond$(if ($milliseconds -ne 1) { 's' })" }
                }
                elseif ($Format -eq 'short') {
                    # Short format: "2d 3h 15m"
                    $days = [Math]::Floor($TimeSpan.TotalDays)
                    $hours = $TimeSpan.Hours
                    $minutes = $TimeSpan.Minutes
                    $seconds = $TimeSpan.Seconds
                    
                    if ($days -gt 0) { $parts += "${days}d" }
                    if ($hours -gt 0) { $parts += "${hours}h" }
                    if ($minutes -gt 0) { $parts += "${minutes}m" }
                    if ($seconds -gt 0 -and $days -eq 0 -and $hours -eq 0) { $parts += "${seconds}s" }
                }
                elseif ($Format -eq 'iso8601') {
                    # ISO 8601 duration format: P1DT2H3M4S
                    $days = [Math]::Floor($TimeSpan.TotalDays)
                    $hours = $TimeSpan.Hours
                    $minutes = $TimeSpan.Minutes
                    $seconds = $TimeSpan.Seconds
                    
                    $result = "P"
                    if ($days -gt 0) { $result += "${days}D" }
                    if ($hours -gt 0 -or $minutes -gt 0 -or $seconds -gt 0) {
                        $result += "T"
                        if ($hours -gt 0) { $result += "${hours}H" }
                        if ($minutes -gt 0) { $result += "${minutes}M" }
                        if ($seconds -gt 0) { $result += "${seconds}S" }
                    }
                    return $result
                }
                else {
                    # Custom format - use TimeSpan.ToString
                    return $TimeSpan.ToString($Format)
                }
                
                if ($parts.Count -eq 0) {
                    return "0 seconds"
                }
                
                return $parts -join ' '
            }
            catch {
                throw "Failed to convert TimeSpan to duration: $_"
            }
        }
    } -Force

    # Duration to seconds
    Set-Item -Path Function:Global:_ConvertFrom-DurationToSeconds -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$DurationString
        )
        process {
            try {
                $timeSpan = _ConvertFrom-DurationToTimeSpan -DurationString $DurationString
                return $timeSpan.TotalSeconds
            }
            catch {
                throw "Failed to convert duration to seconds: $_"
            }
        }
    } -Force

    # Seconds to Duration
    Set-Item -Path Function:Global:_ConvertTo-DurationFromSeconds -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Seconds,
            [string]$Format = 'long'
        )
        process {
            try {
                $timeSpan = [TimeSpan]::FromSeconds($Seconds)
                return _ConvertTo-DurationFromTimeSpan -TimeSpan $timeSpan -Format $Format
            }
            catch {
                throw "Failed to convert seconds to duration: $_"
            }
        }
    } -Force

    # Duration to milliseconds
    Set-Item -Path Function:Global:_ConvertFrom-DurationToMilliseconds -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$DurationString
        )
        process {
            try {
                $timeSpan = _ConvertFrom-DurationToTimeSpan -DurationString $DurationString
                return $timeSpan.TotalMilliseconds
            }
            catch {
                throw "Failed to convert duration to milliseconds: $_"
            }
        }
    } -Force

    # Milliseconds to Duration
    Set-Item -Path Function:Global:_ConvertTo-DurationFromMilliseconds -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$Milliseconds,
            [string]$Format = 'long'
        )
        process {
            try {
                $timeSpan = [TimeSpan]::FromMilliseconds($Milliseconds)
                return _ConvertTo-DurationFromTimeSpan -TimeSpan $timeSpan -Format $Format
            }
            catch {
                throw "Failed to convert milliseconds to duration: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert Human-readable duration to TimeSpan
<#
.SYNOPSIS
    Converts a human-readable duration string to a TimeSpan object.
.DESCRIPTION
    Converts natural language duration expressions to TimeSpan objects.
    Supports expressions like "2 hours", "30 minutes", "1 day 3 hours 15 minutes", etc.
.PARAMETER DurationString
    The human-readable duration string to convert.
.EXAMPLE
    "2 hours" | ConvertFrom-DurationToTimeSpan
    
    Converts "2 hours" to a TimeSpan object.
.EXAMPLE
    "1 day 3 hours 15 minutes" | ConvertFrom-DurationToTimeSpan
    
    Converts a complex duration to a TimeSpan object.
.EXAMPLE
    "3600" | ConvertFrom-DurationToTimeSpan
    
    Converts a number (assumed to be seconds) to a TimeSpan object.
.OUTPUTS
    System.TimeSpan
    Returns a TimeSpan object representing the duration.
#>
function ConvertFrom-DurationToTimeSpan {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$DurationString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-DurationToTimeSpan @PSBoundParameters
}
Set-Alias -Name duration-to-timespan -Value ConvertFrom-DurationToTimeSpan -ErrorAction SilentlyContinue

# Convert TimeSpan to Human-readable duration
<#
.SYNOPSIS
    Converts a TimeSpan object to a human-readable duration string.
.DESCRIPTION
    Converts a TimeSpan object to a human-readable duration string.
.PARAMETER TimeSpan
    The TimeSpan object to convert.
.PARAMETER Format
    The format to use: 'long' (default) for "2 days 3 hours", 'short' for "2d 3h", 'iso8601' for "P2DT3H", or a custom format string.
.EXAMPLE
    New-TimeSpan -Days 2 -Hours 3 -Minutes 15 | ConvertTo-DurationFromTimeSpan
    
    Converts a TimeSpan to "2 days 3 hours 15 minutes".
.EXAMPLE
    New-TimeSpan -Hours 2 | ConvertTo-DurationFromTimeSpan -Format 'short'
    
    Converts to "2h".
.EXAMPLE
    New-TimeSpan -Days 1 -Hours 2 -Minutes 3 | ConvertTo-DurationFromTimeSpan -Format 'iso8601'
    
    Converts to "P1DT2H3M" (ISO 8601 duration format).
.OUTPUTS
    System.String
    Returns a human-readable duration string.
#>
function ConvertTo-DurationFromTimeSpan {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [TimeSpan]$TimeSpan,
        [string]$Format = 'long'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-DurationFromTimeSpan @PSBoundParameters
}
Set-Alias -Name timespan-to-duration -Value ConvertTo-DurationFromTimeSpan -ErrorAction SilentlyContinue

# Additional conversion functions
function ConvertFrom-DurationToSeconds {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$DurationString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-DurationToSeconds @PSBoundParameters
}
Set-Alias -Name duration-to-seconds -Value ConvertFrom-DurationToSeconds -ErrorAction SilentlyContinue

function ConvertTo-DurationFromSeconds {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$Seconds,
        [string]$Format = 'long'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-DurationFromSeconds @PSBoundParameters
}
Set-Alias -Name seconds-to-duration -Value ConvertTo-DurationFromSeconds -ErrorAction SilentlyContinue

function ConvertFrom-DurationToMilliseconds {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$DurationString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-DurationToMilliseconds @PSBoundParameters
}
Set-Alias -Name duration-to-milliseconds -Value ConvertFrom-DurationToMilliseconds -ErrorAction SilentlyContinue

function ConvertTo-DurationFromMilliseconds {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$Milliseconds,
        [string]$Format = 'long'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-DurationFromMilliseconds @PSBoundParameters
}
Set-Alias -Name milliseconds-to-duration -Value ConvertTo-DurationFromMilliseconds -ErrorAction SilentlyContinue

