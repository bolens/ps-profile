# ConvertFrom-HumanReadableToRfc3339

## Synopsis

Converts a DateTime object to a human-readable string.

## Description

Converts a DateTime object to a human-readable relative or formatted string.

## Signature

```powershell
ConvertFrom-HumanReadableToRfc3339
```

## Parameters

### -DateTime

The DateTime object to convert.

### -Format

The format to use: 'relative' (default) for relative times like "2 hours ago", or a standard DateTime format string.


## Outputs

System.String Returns a human-readable date string.


## Examples

### Example 1

`powershell
Get-Date | ConvertTo-HumanReadableFromDateTime
    
    Converts the current date/time to a human-readable relative string.
``

### Example 2

`powershell
(Get-Date).AddDays(-2) | ConvertTo-HumanReadableFromDateTime
    
    Converts a date 2 days ago to "2 days ago".
``

### Example 3

`powershell
Get-Date | ConvertTo-HumanReadableFromDateTime -Format 'MMMM d, yyyy'
    
    Converts to a formatted string like "January 15, 2024".
``

## Aliases

This function has the following aliases:

- `human-to-rfc3339` - Converts a DateTime object to a human-readable string.


## Source

Defined in: ../profile.d/conversion-modules/data/time/human-readable.ps1
