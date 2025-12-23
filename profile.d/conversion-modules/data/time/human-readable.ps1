# ===============================================
# Human-readable date/time conversion utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Human-readable date/time conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for human-readable date/time format conversions.
    Supports conversions between natural language dates and DateTime objects, Unix timestamps, ISO 8601, and RFC 3339.
    This function is called automatically by Ensure-FileConversion-Data.
.NOTES
    This is an internal initialization function and should not be called directly.
    Supports natural language date expressions like "tomorrow", "next week", "2 days ago", "in 3 hours", etc.
#>
function Initialize-FileConversion-CoreTimeHumanReadable {
    # Human-readable to DateTime
    Set-Item -Path Function:Global:_ConvertFrom-HumanReadableToDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$HumanReadableString
        )
        process {
            try {
                $now = Get-Date
                $input = $HumanReadableString.Trim().ToLower()
                
                # Handle relative dates
                if ($input -match '^(now|today)$') {
                    return $now.Date
                }
                elseif ($input -match '^tomorrow$') {
                    return $now.Date.AddDays(1)
                }
                elseif ($input -match '^yesterday$') {
                    return $now.Date.AddDays(-1)
                }
                elseif ($input -match '^next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$') {
                    $dayName = $matches[1]
                    $targetDay = [System.DayOfWeek]$dayName
                    $daysUntil = ($targetDay - $now.DayOfWeek + 7) % 7
                    if ($daysUntil -eq 0) { $daysUntil = 7 }
                    return $now.Date.AddDays($daysUntil)
                }
                elseif ($input -match '^last\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$') {
                    $dayName = $matches[1]
                    $targetDay = [System.DayOfWeek]$dayName
                    $daysSince = ($now.DayOfWeek - $targetDay + 7) % 7
                    if ($daysSince -eq 0) { $daysSince = 7 }
                    return $now.Date.AddDays(-$daysSince)
                }
                elseif ($input -match '^(\d+)\s+(second|seconds|minute|minutes|hour|hours|day|days|week|weeks|month|months|year|years)\s+ago$') {
                    $amount = [int]$matches[1]
                    $unit = $matches[2]
                    $subtract = switch ($unit) {
                        { $_ -match '^second' } { New-TimeSpan -Seconds $amount }
                        { $_ -match '^minute' } { New-TimeSpan -Minutes $amount }
                        { $_ -match '^hour' } { New-TimeSpan -Hours $amount }
                        { $_ -match '^day' } { New-TimeSpan -Days $amount }
                        { $_ -match '^week' } { New-TimeSpan -Days ($amount * 7) }
                        { $_ -match '^month' } { $now.AddMonths(-$amount) - $now }
                        { $_ -match '^year' } { $now.AddYears(-$amount) - $now }
                    }
                    if ($unit -match '^(month|year)') {
                        return $now.Add($subtract)
                    }
                    else {
                        return $now.Subtract($subtract)
                    }
                }
                elseif ($input -match '^(in\s+)?(\d+)\s+(second|seconds|minute|minutes|hour|hours|day|days|week|weeks|month|months|year|years)$') {
                    $amount = [int]$matches[2]
                    $unit = $matches[3]
                    $add = switch ($unit) {
                        { $_ -match '^second' } { New-TimeSpan -Seconds $amount }
                        { $_ -match '^minute' } { New-TimeSpan -Minutes $amount }
                        { $_ -match '^hour' } { New-TimeSpan -Hours $amount }
                        { $_ -match '^day' } { New-TimeSpan -Days $amount }
                        { $_ -match '^week' } { New-TimeSpan -Days ($amount * 7) }
                        { $_ -match '^month' } { $now.AddMonths($amount) - $now }
                        { $_ -match '^year' } { $now.AddYears($amount) - $now }
                    }
                    if ($unit -match '^(month|year)') {
                        return $now.Add($add)
                    }
                    else {
                        return $now.Add($add)
                    }
                }
                elseif ($input -match '^next\s+(week|month|year)$') {
                    $unit = $matches[1]
                    $result = switch ($unit) {
                        'week' { $now.Date.AddDays(7 - [int]$now.DayOfWeek) }
                        'month' { $now.Date.AddMonths(1).AddDays(-$now.Day + 1) }
                        'year' { $now.Date.AddYears(1).AddDays(-$now.DayOfYear + 1) }
                    }
                    return $result
                }
                else {
                    # Try parsing as standard date format
                    try {
                        return [DateTime]::Parse($HumanReadableString, [System.Globalization.CultureInfo]::InvariantCulture)
                    }
                    catch {
                        throw "Could not parse human-readable date: $HumanReadableString"
                    }
                }
            }
            catch {
                throw "Failed to convert human-readable date to DateTime: $_"
            }
        }
    } -Force

    # DateTime to Human-readable
    Set-Item -Path Function:Global:_ConvertTo-HumanReadableFromDateTime -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [DateTime]$DateTime,
            [string]$Format = 'relative'
        )
        process {
            try {
                $now = Get-Date
                $diff = $DateTime - $now
                $daysDiff = [Math]::Floor($diff.TotalDays)
                
                if ($Format -eq 'relative') {
                    # Relative format
                    if ([Math]::Abs($diff.TotalSeconds) -lt 60) {
                        return if ($diff.TotalSeconds -gt 0) { "in $([Math]::Round($diff.TotalSeconds)) seconds" } else { "$([Math]::Round([Math]::Abs($diff.TotalSeconds))) seconds ago" }
                    }
                    elseif ([Math]::Abs($diff.TotalMinutes) -lt 60) {
                        $mins = [Math]::Round($diff.TotalMinutes)
                        return if ($mins -gt 0) { "in $mins minutes" } else { "$([Math]::Abs($mins)) minutes ago" }
                    }
                    elseif ([Math]::Abs($diff.TotalHours) -lt 24) {
                        $hours = [Math]::Round($diff.TotalHours)
                        return if ($hours -gt 0) { "in $hours hours" } else { "$([Math]::Abs($hours)) hours ago" }
                    }
                    elseif ($daysDiff -eq 0) {
                        return if ($diff.TotalHours -gt 0) { "today" } else { "today" }
                    }
                    elseif ($daysDiff -eq 1) {
                        return "tomorrow"
                    }
                    elseif ($daysDiff -eq -1) {
                        return "yesterday"
                    }
                    elseif ($daysDiff -gt 0 -and $daysDiff -lt 7) {
                        return "in $daysDiff days"
                    }
                    elseif ($daysDiff -lt 0 -and [Math]::Abs($daysDiff) -lt 7) {
                        return "$([Math]::Abs($daysDiff)) days ago"
                    }
                    elseif ($daysDiff -ge 7 -and $daysDiff -lt 30) {
                        $weeks = [Math]::Round($daysDiff / 7)
                        return "in $weeks weeks"
                    }
                    elseif ($daysDiff -le -7 -and [Math]::Abs($daysDiff) -lt 30) {
                        $weeks = [Math]::Round([Math]::Abs($daysDiff) / 7)
                        return "$weeks weeks ago"
                    }
                    else {
                        # Use DateTimeFormatting module if available for unified date formatting
                        if (Get-Command Format-DateTime -ErrorAction SilentlyContinue) {
                            return Format-DateTime -DateTime $DateTime -Format 'MMMM d, yyyy'
                        }
                        elseif (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                            # Fallback to Format-LocaleDate if DateTimeFormatting not available
                            return Format-LocaleDate $DateTime -Format 'MMMM d, yyyy'
                        }
                        else {
                            # Final fallback to standard format
                            return $DateTime.ToString('MMMM d, yyyy')
                        }
                    }
                }
                else {
                    # Use DateTimeFormatting module if available for unified date formatting
                    if (Get-Command Format-DateTime -ErrorAction SilentlyContinue) {
                        return Format-DateTime -DateTime $DateTime -Format $Format
                    }
                    elseif (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
                        # Fallback to Format-LocaleDate if DateTimeFormatting not available
                        return Format-LocaleDate $DateTime -Format $Format
                    }
                    else {
                        # Final fallback to standard format
                        return $DateTime.ToString($Format)
                    }
                }
            }
            catch {
                throw "Failed to convert DateTime to human-readable format: $_"
            }
        }
    } -Force

    # Human-readable to Unix Timestamp
    Set-Item -Path Function:Global:_ConvertFrom-HumanReadableToUnixTimestamp -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$HumanReadableString
        )
        process {
            try {
                $dateTime = _ConvertFrom-HumanReadableToDateTime -HumanReadableString $HumanReadableString
                return _ConvertTo-UnixTimestampFromDateTime -DateTime $dateTime
            }
            catch {
                throw "Failed to convert human-readable date to Unix timestamp: $_"
            }
        }
    } -Force

    # Unix Timestamp to Human-readable
    Set-Item -Path Function:Global:_ConvertTo-HumanReadableFromUnixTimestamp -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [double]$UnixTimestamp,
            [string]$Format = 'relative'
        )
        process {
            try {
                $dateTime = _ConvertFrom-UnixTimestampToDateTime -UnixTimestamp $UnixTimestamp
                return _ConvertTo-HumanReadableFromDateTime -DateTime $dateTime -Format $Format
            }
            catch {
                throw "Failed to convert Unix timestamp to human-readable format: $_"
            }
        }
    } -Force

    # Human-readable to ISO 8601
    Set-Item -Path Function:Global:_ConvertFrom-HumanReadableToIso8601 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$HumanReadableString
        )
        process {
            try {
                $dateTime = _ConvertFrom-HumanReadableToDateTime -HumanReadableString $HumanReadableString
                return _ConvertTo-Iso8601FromDateTime -DateTime $dateTime
            }
            catch {
                throw "Failed to convert human-readable date to ISO 8601: $_"
            }
        }
    } -Force

    # ISO 8601 to Human-readable
    Set-Item -Path Function:Global:_ConvertTo-HumanReadableFromIso8601 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Iso8601String,
            [string]$Format = 'relative'
        )
        process {
            try {
                $dateTime = _ConvertFrom-Iso8601ToDateTime -Iso8601String $Iso8601String
                return _ConvertTo-HumanReadableFromDateTime -DateTime $dateTime -Format $Format
            }
            catch {
                throw "Failed to convert ISO 8601 to human-readable format: $_"
            }
        }
    } -Force

    # Human-readable to RFC 3339
    Set-Item -Path Function:Global:_ConvertFrom-HumanReadableToRfc3339 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$HumanReadableString
        )
        process {
            try {
                $dateTime = _ConvertFrom-HumanReadableToDateTime -HumanReadableString $HumanReadableString
                return _ConvertTo-Rfc3339FromDateTime -DateTime $dateTime
            }
            catch {
                throw "Failed to convert human-readable date to RFC 3339: $_"
            }
        }
    } -Force

    # RFC 3339 to Human-readable
    Set-Item -Path Function:Global:_ConvertTo-HumanReadableFromRfc3339 -Value {
        param(
            [Parameter(Mandatory, ValueFromPipeline = $true)]
            [string]$Rfc3339String,
            [string]$Format = 'relative'
        )
        process {
            try {
                $dateTime = _ConvertFrom-Rfc3339ToDateTime -Rfc3339String $Rfc3339String
                return _ConvertTo-HumanReadableFromDateTime -DateTime $dateTime -Format $Format
            }
            catch {
                throw "Failed to convert RFC 3339 to human-readable format: $_"
            }
        }
    } -Force
}

# Public functions and aliases
# Convert Human-readable to DateTime
<#
.SYNOPSIS
    Converts a human-readable date string to a DateTime object.
.DESCRIPTION
    Converts natural language date expressions to DateTime objects.
    Supports expressions like "tomorrow", "next week", "2 days ago", "in 3 hours", etc.
.PARAMETER HumanReadableString
    The human-readable date string to convert.
.EXAMPLE
    "tomorrow" | ConvertFrom-HumanReadableToDateTime
    
    Converts "tomorrow" to a DateTime object.
.EXAMPLE
    "2 days ago" | ConvertFrom-HumanReadableToDateTime
    
    Converts "2 days ago" to a DateTime object.
.EXAMPLE
    "next Monday" | ConvertFrom-HumanReadableToDateTime
    
    Converts "next Monday" to a DateTime object.
.OUTPUTS
    System.DateTime
    Returns a DateTime object representing the parsed date.
#>
function ConvertFrom-HumanReadableToDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$HumanReadableString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HumanReadableToDateTime @PSBoundParameters
}
Set-Alias -Name human-to-datetime -Value ConvertFrom-HumanReadableToDateTime -ErrorAction SilentlyContinue

# Convert DateTime to Human-readable
<#
.SYNOPSIS
    Converts a DateTime object to a human-readable string.
.DESCRIPTION
    Converts a DateTime object to a human-readable relative or formatted string.
.PARAMETER DateTime
    The DateTime object to convert.
.PARAMETER Format
    The format to use: 'relative' (default) for relative times like "2 hours ago", or a standard DateTime format string.
.EXAMPLE
    Get-Date | ConvertTo-HumanReadableFromDateTime
    
    Converts the current date/time to a human-readable relative string.
.EXAMPLE
    (Get-Date).AddDays(-2) | ConvertTo-HumanReadableFromDateTime
    
    Converts a date 2 days ago to "2 days ago".
.EXAMPLE
    Get-Date | ConvertTo-HumanReadableFromDateTime -Format 'MMMM d, yyyy'
    
    Converts to a formatted string like "January 15, 2024".
.OUTPUTS
    System.String
    Returns a human-readable date string.
#>
function ConvertTo-HumanReadableFromDateTime {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [DateTime]$DateTime,
        [string]$Format = 'relative'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-HumanReadableFromDateTime @PSBoundParameters
}
Set-Alias -Name datetime-to-human -Value ConvertTo-HumanReadableFromDateTime -ErrorAction SilentlyContinue

# Additional conversion aliases
Set-Alias -Name human-to-unix -Value ConvertFrom-HumanReadableToUnixTimestamp -ErrorAction SilentlyContinue
Set-Alias -Name unix-to-human -Value ConvertTo-HumanReadableFromUnixTimestamp -ErrorAction SilentlyContinue
Set-Alias -Name human-to-iso8601 -Value ConvertFrom-HumanReadableToIso8601 -ErrorAction SilentlyContinue
Set-Alias -Name iso8601-to-human -Value ConvertTo-HumanReadableFromIso8601 -ErrorAction SilentlyContinue
Set-Alias -Name human-to-rfc3339 -Value ConvertFrom-HumanReadableToRfc3339 -ErrorAction SilentlyContinue
Set-Alias -Name rfc3339-to-human -Value ConvertTo-HumanReadableFromRfc3339 -ErrorAction SilentlyContinue

# Helper functions for public API
function ConvertFrom-HumanReadableToUnixTimestamp {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$HumanReadableString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HumanReadableToUnixTimestamp @PSBoundParameters
}

function ConvertTo-HumanReadableFromUnixTimestamp {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [double]$UnixTimestamp,
        [string]$Format = 'relative'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-HumanReadableFromUnixTimestamp @PSBoundParameters
}

function ConvertFrom-HumanReadableToIso8601 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$HumanReadableString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HumanReadableToIso8601 @PSBoundParameters
}

function ConvertTo-HumanReadableFromIso8601 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Iso8601String,
        [string]$Format = 'relative'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-HumanReadableFromIso8601 @PSBoundParameters
}

function ConvertFrom-HumanReadableToRfc3339 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$HumanReadableString
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertFrom-HumanReadableToRfc3339 @PSBoundParameters
}

function ConvertTo-HumanReadableFromRfc3339 {
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Rfc3339String,
        [string]$Format = 'relative'
    )
    if (-not $global:FileConversionDataInitialized) { Ensure-FileConversion-Data }
    _ConvertTo-HumanReadableFromRfc3339 @PSBoundParameters
}

