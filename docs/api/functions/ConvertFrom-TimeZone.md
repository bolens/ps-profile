# ConvertFrom-TimeZone

## Synopsis

Converts a DateTime from a specific timezone to local time.

## Description

Converts a DateTime object (assumed to be in the specified timezone) to local time.

## Signature

```powershell
ConvertFrom-TimeZone
```

## Parameters

### -DateTime

The DateTime object to convert (assumed to be in the specified timezone).

### -TimeZone

The source timezone ID (e.g., "Eastern Standard Time", "UTC", "GMT").


## Outputs

System.DateTime Returns a DateTime object in local time.


## Examples

### Example 1

`powershell
[DateTime]::Parse("2024-01-15 12:00:00") | ConvertFrom-TimeZone -TimeZone "UTC"
    
    Converts a UTC date/time to local time.
``

## Aliases

This function has the following aliases:

- `timezone-to-datetime` - Converts a DateTime from a specific timezone to local time.


## Source

Defined in: ../profile.d/conversion-modules/data/time/timezone.ps1
