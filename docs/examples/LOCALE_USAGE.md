# Using Locale-Aware Output

This guide demonstrates how to use the `Locale.psm1` module to format output based on the user's system locale.

## Importing the Module

```powershell
# Import the module (usually done via Import-LibModule in utility scripts)
$modulePath = Join-Path $PSScriptRoot '..' 'lib' 'core' 'Locale.psm1'
Import-Module $modulePath -DisableNameChecking
```

## Basic Usage

### Detecting User Locale

```powershell
# Get full locale information
$locale = Get-UserLocale
Write-Host "Language: $($locale.LanguageCode)"
Write-Host "Region: $($locale.RegionCode)"
Write-Host "Is UK English: $($locale.IsUKEnglish)"
Write-Host "Is US English: $($locale.IsUSEnglish)"

# Quick checks
if (Test-IsUKEnglish) {
    Write-Host "Using UK English formatting"
}
elseif (Test-IsUSEnglish) {
    Write-Host "Using US English formatting"
}
```

### Formatting Dates

```powershell
$date = Get-Date

# Use locale's default format
$formatted = Format-LocaleDate $date
Write-Host "Date: $formatted"  # Output: "12/2/2025 4:47:31 PM" (US) or "02/12/2025 16:47:31" (UK)

# Use specific format
$shortDate = Format-LocaleDate $date -Format "d"  # Short date format
$longDate = Format-LocaleDate $date -Format "D"    # Long date format
```

### Formatting Numbers

```powershell
# Format number with locale-specific separators
$number = 1234567.89
$formatted = Format-LocaleNumber $number
Write-Host "Number: $formatted"  # Output: "1234567.89" (US) or "1234567,89" (some locales)

# Format with specific precision
$formatted = Format-LocaleNumber $number -Format "N2"  # 2 decimal places
```

### Formatting Currency

```powershell
$amount = 1234.56
$currency = Format-LocaleCurrency $amount
Write-Host "Amount: $currency"  # Output: "$1,234.56" (US) or "£1,234.56" (UK)
```

### Localized Messages

```powershell
# Provide different messages for UK vs US English
$message = Get-LocalizedMessage `
    -USMessage "The file was canceled" `
    -UKMessage "The file was cancelled"
Write-Host $message

# For spelling differences
$colorMsg = Get-LocalizedMessage -USMessage "Color" -UKMessage "Colour"
$meterMsg = Get-LocalizedMessage -USMessage "meter" -UKMessage "metre"
```

### Combined Formatting

```powershell
# Format multiple values at once
$formatted = Format-LocaleOutput `
    -Date (Get-Date) `
    -Number 1234.56 `
    -Currency 99.99

Write-Host "Date: $($formatted.Date)"
Write-Host "Number: $($formatted.Number)"
Write-Host "Currency: $($formatted.Currency)"
```

## Real-World Examples

### Example 1: Error Message with Localized Spelling

```powershell
function Write-OperationStatus {
    param([bool]$Success)

    if ($Success) {
        $message = Get-LocalizedMessage `
            -USMessage "Operation completed successfully" `
            -UKMessage "Operation completed successfully"
    }
    else {
        $message = Get-LocalizedMessage `
            -USMessage "Operation was canceled" `
            -UKMessage "Operation was cancelled"
    }

    Write-Host $message
}
```

### Example 2: Formatted Report with Locale-Aware Values

```powershell
function Write-Report {
    param(
        [DateTime]$ReportDate,
        [double]$TotalAmount,
        [int]$ItemCount
    )

    $locale = Get-UserLocale
    $dateStr = Format-LocaleDate $ReportDate -Format "D"
    $amountStr = Format-LocaleCurrency $TotalAmount

    Write-Host "Report Date: $dateStr"
    Write-Host "Total Amount: $amountStr"
    Write-Host "Item Count: $ItemCount"
}
```

### Example 3: Conditional Output Based on Locale

```powershell
function Write-LocaleAwareMessage {
    param([string]$Message)

    $locale = Get-UserLocale

    if ($locale.IsUKEnglish) {
        # Use UK-specific formatting or wording
        Write-Host "[UK] $Message" -ForegroundColor Green
    }
    elseif ($locale.IsUSEnglish) {
        # Use US-specific formatting or wording
        Write-Host "[US] $Message" -ForegroundColor Blue
    }
    else {
        # Fallback for other locales
        Write-Host $Message
    }
}
```

## Integration with Existing Code

### Using in Utility Scripts

```powershell
# At the top of your utility script
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking

# Later in your script
$locale = Get-UserLocale
$formattedDate = Format-LocaleDate (Get-Date)
Write-ScriptMessage -Message "Report generated on $formattedDate"
```

## Notes

- The module uses `Get-Culture` and `Get-UICulture` to detect the user's locale
- UK English is detected when the locale is `en-GB`
- US English is detected when the locale is `en-US`
- All formatting respects the user's system locale settings
- For non-English locales, the module still provides formatting functions but may not distinguish UK/US variants
