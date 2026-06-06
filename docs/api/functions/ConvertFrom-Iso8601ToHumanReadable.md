# ConvertFrom-Iso8601ToHumanReadable

## Synopsis

Converts an ISO 8601 date/time string to a human-readable format.

## Description

Converts an ISO 8601 formatted date/time string to a human-readable date/time format.

## Signature

```powershell
ConvertFrom-Iso8601ToHumanReadable
```

## Parameters

### -Iso8601String

The ISO 8601 formatted date/time string to convert.

### -Format

The format string to use (default: 'F' for full date/time). See DateTime.ToString() format strings for options.


## Outputs

System.String Returns a human-readable date/time string.


## Examples

### Example 1

`powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToHumanReadable
    
    Converts an ISO 8601 string to a human-readable format.
``

### Example 2

`powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToHumanReadable -Format 'yyyy-MM-dd'
    
    Converts using a custom format.
``

## Aliases

This function has the following aliases:

- `iso8601-to-readable` - Converts an ISO 8601 date/time string to a human-readable format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/iso8601.ps1
