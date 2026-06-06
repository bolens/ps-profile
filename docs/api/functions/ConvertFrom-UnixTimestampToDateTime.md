# ConvertFrom-UnixTimestampToDateTime

## Synopsis

Converts a Unix timestamp to a DateTime object.

## Description

Converts a Unix timestamp (seconds since January 1, 1970 UTC) to a DateTime object.

## Signature

```powershell
ConvertFrom-UnixTimestampToDateTime
```

## Parameters

### -UnixTimestamp

The Unix timestamp to convert (as integer or floating-point number).


## Outputs

System.DateTime Returns a DateTime object representing the timestamp.


## Examples

### Example 1

`powershell
1609459200 | ConvertFrom-UnixTimestampToDateTime
    
    Converts the Unix timestamp 1609459200 to a DateTime object.
``

### Example 2

`powershell
1609459200.5 | ConvertFrom-UnixTimestampToDateTime
    
    Converts a Unix timestamp with fractional seconds.
``

## Aliases

This function has the following aliases:

- `unix-to-datetime` - Converts a Unix timestamp to a DateTime object.


## Source

Defined in: ../profile.d/conversion-modules/data/time/unix.ps1
