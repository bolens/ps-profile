# ConvertFrom-Iso8601ToRfc3339

## Synopsis

Converts an ISO 8601 date/time string to RFC 3339 format.

## Description

Converts an ISO 8601 formatted date/time string to RFC 3339 format. RFC 3339 is a profile of ISO 8601 with some restrictions.

## Signature

```powershell
ConvertFrom-Iso8601ToRfc3339
```

## Parameters

### -Iso8601String

The ISO 8601 formatted date/time string to convert.


## Outputs

System.String Returns an RFC 3339 formatted date/time string.


## Examples

### Example 1

```powershell
'2021-01-01T00:00:00Z' | ConvertFrom-Iso8601ToRfc3339
```

Converts an ISO 8601 string to RFC 3339 format.

## Aliases

This function has the following aliases:

- `iso8601-to-rfc3339` - Converts an ISO 8601 date/time string to RFC 3339 format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/iso8601.ps1
