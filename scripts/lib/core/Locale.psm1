<#
scripts/lib/core/Locale.psm1

.SYNOPSIS
    Locale detection and formatting utilities.

.DESCRIPTION
    Provides functions for detecting the user's locale and formatting output
    (dates, numbers, currency, messages) based on their system locale settings.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Gets the current user locale information.

.DESCRIPTION
    Returns detailed information about the current culture and UI culture,
    including language, region, and formatting preferences.

.OUTPUTS
    PSCustomObject with locale information

.EXAMPLE
    $locale = Get-UserLocale
    Write-Host "Language: $($locale.LanguageCode)"
    Write-Host "Region: $($locale.RegionCode)"
#>
function Get-UserLocale {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $culture = Get-Culture
    $uiCulture = Get-UICulture

    # Determine if UK English or US English
    $isUKEnglish = $culture.Name -eq 'en-GB' -or $uiCulture.Name -eq 'en-GB'
    $isUSEnglish = $culture.Name -eq 'en-US' -or $uiCulture.Name -eq 'en-US'
    $isEnglish = $culture.TwoLetterISOLanguageName -eq 'en'

    # Determine English variant
    $englishVariant = if ($isUKEnglish) {
        'UK'
    }
    elseif ($isUSEnglish) {
        'US'
    }
    elseif ($isEnglish) {
        'Other'
    }
    else {
        $null
    }
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Host "  [locale.get-user-locale] Detected locale: Culture=$($culture.Name), UICulture=$($uiCulture.Name), EnglishVariant=$englishVariant" -ForegroundColor DarkGray
    }
    
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [locale.get-user-locale] Detailed locale info: LanguageCode=$($culture.TwoLetterISOLanguageName), RegionCode=$(if ($culture.Name -match '-(\w+)$') { $matches[1] } else { 'N/A' }), DisplayName=$($culture.DisplayName)" -ForegroundColor DarkGray
    }

    return [PSCustomObject]@{
        Culture         = $culture
        UICulture       = $uiCulture
        Name            = $culture.Name
        DisplayName     = $culture.DisplayName
        LanguageCode    = $culture.TwoLetterISOLanguageName
        RegionCode      = if ($culture.Name -match '-(\w+)$') { $matches[1] } else { $null }
        IetfLanguageTag = $culture.IetfLanguageTag
        IsUKEnglish     = $isUKEnglish
        IsUSEnglish     = $isUSEnglish
        IsEnglish       = $isEnglish
        EnglishVariant  = $englishVariant
        NumberFormat    = $culture.NumberFormat
        DateTimeFormat  = $culture.DateTimeFormat
    }
}

<#
.SYNOPSIS
    Checks if the current locale is UK English.

.DESCRIPTION
    Returns true if the user's locale is set to UK English (en-GB).

.OUTPUTS
    Boolean

.EXAMPLE
    if (Test-IsUKEnglish) {
        Write-Host "Using UK English formatting"
    }
#>
function Test-IsUKEnglish {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $locale = Get-UserLocale
    return $locale.IsUKEnglish
}

<#
.SYNOPSIS
    Checks if the current locale is US English.

.DESCRIPTION
    Returns true if the user's locale is set to US English (en-US).

.OUTPUTS
    Boolean

.EXAMPLE
    if (Test-IsUSEnglish) {
        Write-Host "Using US English formatting"
    }
#>
function Test-IsUSEnglish {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $locale = Get-UserLocale
    return $locale.IsUSEnglish
}

<#
.SYNOPSIS
    Formats a date using the user's locale settings.

.DESCRIPTION
    Formats a date or datetime object according to the user's locale-specific
    date and time formatting preferences.

.PARAMETER Date
    The date or datetime object to format.

.PARAMETER Format
    Optional format string. If not specified, uses the locale's default format.

.OUTPUTS
    Formatted date string

.EXAMPLE
    Format-LocaleDate (Get-Date)
    
.EXAMPLE
    Format-LocaleDate (Get-Date) -Format "d"
#>
function Format-LocaleDate {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [DateTime]$Date,

        [string]$Format
    )

    $locale = Get-UserLocale

    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        $formatStr = if ($Format) { $Format } else { 'default' }
        Write-Host "  [locale.format-date] Formatting date with locale $($locale.Name), format: $formatStr" -ForegroundColor DarkGray
    }

    if ($Format) {
        return $Date.ToString($Format, $locale.Culture)
    }
    else {
        return $Date.ToString($locale.Culture)
    }
}

<#
.SYNOPSIS
    Formats a number using the user's locale settings.

.DESCRIPTION
    Formats a number according to the user's locale-specific number formatting
    preferences (decimal separator, thousands separator, etc.).

.PARAMETER Number
    The number to format.

.PARAMETER Format
    Optional format string (e.g., "N2" for number with 2 decimal places).

.OUTPUTS
    Formatted number string

.EXAMPLE
    Format-LocaleNumber 1234.56
    
.EXAMPLE
    Format-LocaleNumber 1234.56 -Format "N2"
#>
function Format-LocaleNumber {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [double]$Number,

        [string]$Format
    )

    $locale = Get-UserLocale

    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        $formatStr = if ($Format) { $Format } else { 'default' }
        Write-Host "  [locale.format-number] Formatting number with locale $($locale.Name), format: $formatStr" -ForegroundColor DarkGray
    }

    if ($Format) {
        return $Number.ToString($Format, $locale.Culture)
    }
    else {
        return $Number.ToString($locale.Culture)
    }
}

<#
.SYNOPSIS
    Formats currency using the user's locale settings.

.DESCRIPTION
    Formats a number as currency according to the user's locale-specific
    currency formatting preferences.

.PARAMETER Amount
    The amount to format as currency.

.OUTPUTS
    Formatted currency string

.EXAMPLE
    Format-LocaleCurrency 1234.56
#>
function Format-LocaleCurrency {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [double]$Amount
    )

    $locale = Get-UserLocale
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [locale.format-currency] Formatting currency with locale $($locale.Name)" -ForegroundColor DarkGray
    }
    
    return $Amount.ToString('C', $locale.Culture)
}

<#
.SYNOPSIS
    Gets a localized message based on the user's locale.

.DESCRIPTION
    Returns a message variant based on the user's locale. Useful for
    providing different wording or spelling based on UK vs US English.

.PARAMETER USMessage
    The US English version of the message.

.PARAMETER UKMessage
    The UK English version of the message. If not provided, uses USMessage.

.PARAMETER DefaultMessage
    Optional default message if locale cannot be determined.

.OUTPUTS
    Localized message string

.EXAMPLE
    $msg = Get-LocalizedMessage -USMessage "Color" -UKMessage "Colour"
    Write-Host $msg

.EXAMPLE
    $msg = Get-LocalizedMessage -USMessage "The file was canceled" -UKMessage "The file was cancelled"
    Write-Host $msg
#>
function Get-LocalizedMessage {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$USMessage,

        [string]$UKMessage,

        [string]$DefaultMessage
    )

    $locale = Get-UserLocale

    $selectedMessage = $null
    $selectedVariant = $null
    
    if ($locale.IsUKEnglish -and $UKMessage) {
        $selectedMessage = $UKMessage
        $selectedVariant = 'UK'
    }
    elseif ($locale.IsUSEnglish) {
        $selectedMessage = $USMessage
        $selectedVariant = 'US'
    }
    elseif ($DefaultMessage) {
        $selectedMessage = $DefaultMessage
        $selectedVariant = 'Default'
    }
    else {
        $selectedMessage = $USMessage
        $selectedVariant = 'US (fallback)'
    }
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [locale.get-localized-message] Selected message variant: $selectedVariant (Locale: $($locale.Name))" -ForegroundColor DarkGray
    }
    
    return $selectedMessage
}

<#
.SYNOPSIS
    Formats output with locale-aware formatting.

.DESCRIPTION
    Formats various data types (dates, numbers, currency) using the user's
    locale settings in a single call.

.PARAMETER Date
    Optional date to format.

.PARAMETER Number
    Optional number to format.

.PARAMETER Currency
    Optional currency amount to format.

.PARAMETER DateFormat
    Optional date format string.

.PARAMETER NumberFormat
    Optional number format string.

.OUTPUTS
    PSCustomObject with formatted values

.EXAMPLE
    $formatted = Format-LocaleOutput -Date (Get-Date) -Number 1234.56 -Currency 99.99
    Write-Host "Date: $($formatted.Date), Number: $($formatted.Number), Currency: $($formatted.Currency)"
#>
function Format-LocaleOutput {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [DateTime]$Date,

        [double]$Number,

        [double]$Currency,

        [string]$DateFormat,

        [string]$NumberFormat
    )

    $locale = Get-UserLocale
    $result = @{}
    
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        $formats = @()
        if ($PSBoundParameters.ContainsKey('Date')) { $formats += "Date" }
        if ($PSBoundParameters.ContainsKey('Number')) { $formats += "Number" }
        if ($PSBoundParameters.ContainsKey('Currency')) { $formats += "Currency" }
        Write-Host "  [locale.format-output] Formatting with locale $($locale.Name): $($formats -join ', ')" -ForegroundColor DarkGray
    }

    if ($PSBoundParameters.ContainsKey('Date')) {
        if ($DateFormat) {
            $result.Date = $Date.ToString($DateFormat, $locale.Culture)
        }
        else {
            $result.Date = $Date.ToString($locale.Culture)
        }
    }

    if ($PSBoundParameters.ContainsKey('Number')) {
        if ($NumberFormat) {
            $result.Number = $Number.ToString($NumberFormat, $locale.Culture)
        }
        else {
            $result.Number = $Number.ToString($locale.Culture)
        }
    }

    if ($PSBoundParameters.ContainsKey('Currency')) {
        $result.Currency = $Currency.ToString('C', $locale.Culture)
    }

    return [PSCustomObject]$result
}

# Export functions
Export-ModuleMember -Function @(
    'Get-UserLocale',
    'Test-IsUKEnglish',
    'Test-IsUSEnglish',
    'Format-LocaleDate',
    'Format-LocaleNumber',
    'Format-LocaleCurrency',
    'Get-LocalizedMessage',
    'Format-LocaleOutput'
)


