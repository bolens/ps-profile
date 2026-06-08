# ConvertFrom-Iso8601ToUnixTimestamp

## Synopsis

Converts an ISO 8601 date/time string to a Unix timestamp.

## Description

Converts an ISO 8601 formatted date/time string to a Unix timestamp.

## Signature

```powershell
ConvertFrom-Iso8601ToUnixTimestamp
```

## Parameters

### -Iso8601String

The ISO 8601 formatted date/time string to convert.


## Outputs

System.Int64 Returns a Unix timestamp as a long integer.


## Examples

### Example 1

```powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToUnixTimestamp
```

Converts an ISO 8601 string to a Unix timestamp.

## Aliases

This function has the following aliases:

- `iso8601-to-unix` - Converts an ISO 8601 date/time string to a Unix timestamp.


## Source

Defined in: ../profile.d/conversion-modules/data/time/iso8601.ps1
