# ConvertTo-Rfc3339FromUnixTimestamp

## Synopsis

Converts a Unix timestamp to RFC 3339 format.

## Description

Converts a Unix timestamp (seconds since epoch) to RFC 3339 formatted date/time string.

## Signature

```powershell
ConvertTo-Rfc3339FromUnixTimestamp
```

## Parameters

### -UnixTimestamp

The Unix timestamp to convert.

### -IncludeMilliseconds

Include milliseconds in the output format.


## Outputs

System.String Returns an RFC 3339 formatted date/time string.


## Examples

### Example 1

```powershell
1609459200 | ConvertTo-Rfc3339FromUnixTimestamp
```

Converts Unix timestamp to RFC 3339 format.

## Aliases

This function has the following aliases:

- `unix-to-rfc3339` - Converts a Unix timestamp to RFC 3339 format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/rfc3339.ps1
