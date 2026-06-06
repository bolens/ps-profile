# ConvertTo-TimeZone

## Synopsis

Converts a DateTime to a specific timezone.

## Description

Converts a DateTime object (assumed to be in local time) to a specific timezone.

## Signature

```powershell
ConvertTo-TimeZone
```

## Parameters

### -DateTime

The DateTime object to convert (assumed to be in local time).

### -TimeZone

The target timezone ID (e.g., "Eastern Standard Time", "UTC", "GMT").


## Outputs

System.DateTime Returns a DateTime object in the target timezone.


## Examples

### Example 1

`powershell
Get-Date | ConvertTo-TimeZone -TimeZone "UTC"
    
    Converts the current local date/time to UTC.
``

## Aliases

This function has the following aliases:

- `datetime-to-timezone` - Converts a DateTime to a specific timezone.


## Source

Defined in: ../profile.d/conversion-modules/data/time/timezone.ps1
