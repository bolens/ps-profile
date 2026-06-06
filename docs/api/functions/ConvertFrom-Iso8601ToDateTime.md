# ConvertFrom-Iso8601ToDateTime

## Synopsis

Converts an ISO 8601 date/time string to a DateTime object.

## Description

Converts an ISO 8601 formatted date/time string to a DateTime object. Supports various ISO 8601 formats including with/without timezone and milliseconds.

## Signature

```powershell
ConvertFrom-Iso8601ToDateTime
```

## Parameters

### -Iso8601String

The ISO 8601 formatted date/time string to convert.


## Outputs

System.DateTime Returns a DateTime object representing the ISO 8601 date/time.


## Examples

### Example 1

`powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToDateTime
    
    Converts an ISO 8601 string to a DateTime object.
``

### Example 2

`powershell
'2021-01-01T12:30:45.123+05:00' | ConvertFrom-Iso8601ToDateTime
    
    Converts an ISO 8601 string with timezone and milliseconds.
``

## Aliases

This function has the following aliases:

- `iso8601-to-datetime` - Converts an ISO 8601 date/time string to a DateTime object.


## Source

Defined in: ../profile.d/conversion-modules/data/time/iso8601.ps1
