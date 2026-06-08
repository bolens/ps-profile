# ConvertTo-Iso8601FromRfc3339

## Synopsis

Converts an RFC 3339 date/time string to ISO 8601 format.

## Description

Converts an RFC 3339 formatted date/time string to ISO 8601 format. RFC 3339 is a profile of ISO 8601, so conversion is straightforward.

## Signature

```powershell
ConvertTo-Iso8601FromRfc3339
```

## Parameters

### -Rfc3339String

The RFC 3339 formatted date/time string to convert.


## Outputs

System.String Returns an ISO 8601 formatted date/time string.


## Examples

### Example 1

```powershell
'2021-01-01T00:00:00Z' | ConvertTo-Iso8601FromRfc3339
```

Converts an RFC 3339 string to ISO 8601 format.

## Aliases

This function has the following aliases:

- `rfc3339-to-iso8601` - Converts an RFC 3339 date/time string to ISO 8601 format.


## Source

Defined in: ../profile.d/conversion-modules/data/time/rfc3339.ps1
