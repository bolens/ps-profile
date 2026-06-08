# ConvertTo-UnixTimestampFromDateTime

## Synopsis

Converts a DateTime object to a Unix timestamp.

## Description

Converts a DateTime object to a Unix timestamp (seconds since January 1, 1970 UTC).

## Signature

```powershell
ConvertTo-UnixTimestampFromDateTime
```

## Parameters

### -DateTime

The DateTime object to convert.


## Outputs

System.Int64 Returns a Unix timestamp as a long integer.


## Examples

### Example 1

```powershell
Get-Date | ConvertTo-UnixTimestampFromDateTime
```

Converts the current date/time to a Unix timestamp.

### Example 2

```powershell
[DateTime]::Parse('2021-01-01') | ConvertTo-UnixTimestampFromDateTime
```

Converts a specific date to a Unix timestamp.

## Aliases

This function has the following aliases:

- `datetime-to-unix` - Converts a DateTime object to a Unix timestamp.


## Source

Defined in: ../profile.d/conversion-modules/data/time/unix.ps1
