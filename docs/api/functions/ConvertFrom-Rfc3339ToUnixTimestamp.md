# ConvertFrom-Rfc3339ToUnixTimestamp

## Synopsis

Converts an RFC 3339 date/time string to a Unix timestamp.

## Description

Converts an RFC 3339 formatted date/time string to a Unix timestamp (seconds since epoch).

## Signature

```powershell
ConvertFrom-Rfc3339ToUnixTimestamp
```

## Parameters

### -Rfc3339String

The RFC 3339 formatted date/time string to convert.


## Outputs

System.Double Returns a Unix timestamp (seconds since epoch).


## Examples

### Example 1

```powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Rfc3339ToUnixTimestamp
```

Converts RFC 3339 string to Unix timestamp.

## Aliases

This function has the following aliases:

- `rfc3339-to-unix` - Converts an RFC 3339 date/time string to a Unix timestamp.


## Source

Defined in: ../profile.d/conversion-modules/data/time/rfc3339.ps1
