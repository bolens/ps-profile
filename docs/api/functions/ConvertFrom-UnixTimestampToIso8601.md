# ConvertFrom-UnixTimestampToIso8601

## Synopsis

Converts a Unix timestamp to ISO 8601 format.

## Description

Converts a Unix timestamp to ISO 8601 date/time format string.

## Signature

```powershell
ConvertFrom-UnixTimestampToIso8601
```

## Parameters

### -UnixTimestamp

The Unix timestamp to convert.


## Outputs

System.String Returns an ISO 8601 formatted date/time string.


## Examples

### Example 1

```powershell
1609459200 | ConvertFrom-UnixTimestampToIso8601
```

Converts the Unix timestamp to ISO 8601 format.

## Aliases

This function has the following aliases:

- `unix-to-iso8601` - Converts a Unix timestamp to ISO 8601 format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/unix.ps1
