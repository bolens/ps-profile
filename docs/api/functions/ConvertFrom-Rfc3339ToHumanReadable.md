# ConvertFrom-Rfc3339ToHumanReadable

## Synopsis

Converts an RFC 3339 date/time string to a human-readable format.

## Description

Converts an RFC 3339 formatted date/time string to a human-readable date/time format.

## Signature

```powershell
ConvertFrom-Rfc3339ToHumanReadable
```

## Parameters

### -Rfc3339String

The RFC 3339 formatted date/time string to convert.

### -Format

The format string to use (default: 'F' for full date/time).


## Outputs

System.String Returns a human-readable date/time string.


## Examples

### Example 1

```powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Rfc3339ToHumanReadable
```

Converts RFC 3339 string to human-readable format.

## Aliases

This function has the following aliases:

- `rfc3339-to-human` - Converts an RFC 3339 date/time string to a human-readable format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/rfc3339.ps1
