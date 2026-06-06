# ConvertTo-Iso8601FromUnixTimestamp

## Synopsis

Converts a Unix timestamp to ISO 8601 format.

## Description

Converts a Unix timestamp to an ISO 8601 formatted date/time string.

## Signature

```powershell
ConvertTo-Iso8601FromUnixTimestamp
```

## Parameters

### -UnixTimestamp

The Unix timestamp to convert.

### -IncludeMilliseconds

Include milliseconds in the output (default: false).

### -IncludeTimezone

Include timezone information in the output (default: false).


## Outputs

System.String Returns an ISO 8601 formatted date/time string.


## Examples

### Example 1

`powershell
1609459200 | ConvertTo-Iso8601FromUnixTimestamp
    
    Converts a Unix timestamp to ISO 8601 format.
``

## Aliases

This function has the following aliases:

- `unix-to-iso8601` - Converts a Unix timestamp to ISO 8601 format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/iso8601.ps1
