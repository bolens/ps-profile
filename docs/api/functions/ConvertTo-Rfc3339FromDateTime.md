# ConvertTo-Rfc3339FromDateTime

## Synopsis

Converts a DateTime object to RFC 3339 format.

## Description

Converts a DateTime object to RFC 3339 formatted date/time string. RFC 3339 requires timezone information (Z for UTC or +/-HH:mm offset).

## Signature

```powershell
ConvertTo-Rfc3339FromDateTime
```

## Parameters

### -DateTime

The DateTime object to convert.

### -IncludeMilliseconds

Include milliseconds in the output format.

### -UseLocalTimezone

Use local timezone offset instead of UTC.


## Outputs

System.String Returns an RFC 3339 formatted date/time string.


## Examples

### Example 1

`powershell
Get-Date | ConvertTo-Rfc3339FromDateTime
    
    Converts current date/time to RFC 3339 format.
``

### Example 2

`powershell
Get-Date | ConvertTo-Rfc3339FromDateTime -IncludeMilliseconds
    
    Converts current date/time to RFC 3339 format with milliseconds.
``

## Aliases

This function has the following aliases:

- `datetime-to-rfc3339` - Converts a DateTime object to RFC 3339 format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/rfc3339.ps1
