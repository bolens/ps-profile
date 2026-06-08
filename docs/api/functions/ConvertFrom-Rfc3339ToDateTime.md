# ConvertFrom-Rfc3339ToDateTime

## Synopsis

Converts an RFC 3339 date/time string to a DateTime object.

## Description

Converts an RFC 3339 formatted date/time string to a DateTime object. RFC 3339 is a profile of ISO 8601 with specific formatting requirements.

## Signature

```powershell
ConvertFrom-Rfc3339ToDateTime
```

## Parameters

### -Rfc3339String

The RFC 3339 formatted date/time string to convert.


## Outputs

System.DateTime Returns a DateTime object representing the RFC 3339 date/time.


## Examples

### Example 1

```powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Rfc3339ToDateTime
```

Converts an RFC 3339 string to a DateTime object.

### Example 2

```powershell
'2021-01-01T12:30:45.123+05:00' | ConvertFrom-Rfc3339ToDateTime
```

Converts an RFC 3339 string with timezone and milliseconds.

## Aliases

This function has the following aliases:

- `rfc3339-to-datetime` - Converts an RFC 3339 date/time string to a DateTime object.


## Source

Defined in: ../profile.d/conversion-modules/data/time/rfc3339.ps1
