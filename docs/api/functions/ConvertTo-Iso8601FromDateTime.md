# ConvertTo-Iso8601FromDateTime

## Synopsis

Converts a DateTime object to ISO 8601 format.

## Description

Converts a DateTime object to an ISO 8601 formatted date/time string.

## Signature

```powershell
ConvertTo-Iso8601FromDateTime
```

## Parameters

### -DateTime

The DateTime object to convert.

### -IncludeMilliseconds

Include milliseconds in the output (default: false).

### -IncludeTimezone

Include timezone information in the output (default: false).


## Outputs

System.String Returns an ISO 8601 formatted date/time string.


## Examples

### Example 1

```powershell
Get-Date | ConvertTo-Iso8601FromDateTime
```

Converts the current date/time to ISO 8601 format.

### Example 2

```powershell
Get-Date | ConvertTo-Iso8601FromDateTime -IncludeMilliseconds -IncludeTimezone
```

Converts with milliseconds and timezone information.

## Aliases

This function has the following aliases:

- `datetime-to-iso8601` - Converts a DateTime object to ISO 8601 format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/iso8601.ps1
