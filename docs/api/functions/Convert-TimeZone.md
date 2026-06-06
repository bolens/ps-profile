# Convert-TimeZone

## Synopsis

Converts a DateTime between two timezones.

## Description

Converts a DateTime object from one timezone to another. Uses .NET TimeZoneInfo for timezone conversions.

## Signature

```powershell
Convert-TimeZone
```

## Parameters

### -DateTime

The DateTime object to convert.

### -SourceTimeZone

The source timezone ID (e.g., "Eastern Standard Time", "UTC", "GMT").

### -TargetTimeZone

The target timezone ID (e.g., "Pacific Standard Time", "UTC", "GMT").


## Outputs

System.DateTime Returns a DateTime object in the target timezone.


## Examples

### Example 1

`powershell
Get-Date | Convert-TimeZone -SourceTimeZone "Eastern Standard Time" -TargetTimeZone "Pacific Standard Time"
    
    Converts the current date/time from Eastern to Pacific timezone.
``

### Example 2

`powershell
[DateTime]::Now | Convert-TimeZone -SourceTimeZone "UTC" -TargetTimeZone "Eastern Standard Time"
    
    Converts UTC time to Eastern timezone.
``

## Aliases

This function has the following aliases:

- `tz-convert` - Converts a DateTime between two timezones.


## Source

Defined in: ../profile.d/conversion-modules/data/time/timezone.ps1
