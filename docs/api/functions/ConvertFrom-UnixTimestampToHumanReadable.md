# ConvertFrom-UnixTimestampToHumanReadable

## Synopsis

Converts a Unix timestamp to a human-readable date/time string.

## Description

Converts a Unix timestamp to a human-readable date/time format.

## Signature

```powershell
ConvertFrom-UnixTimestampToHumanReadable
```

## Parameters

### -UnixTimestamp

The Unix timestamp to convert.

### -Format

The format string to use (default: 'F' for full date/time). See DateTime.ToString() format strings for options.


## Outputs

System.String Returns a human-readable date/time string.


## Examples

### Example 1

```powershell
1609459200 | ConvertFrom-UnixTimestampToHumanReadable
```

Converts the Unix timestamp to a human-readable format.

### Example 2

```powershell
1609459200 | ConvertFrom-UnixTimestampToHumanReadable -Format 'yyyy-MM-dd'
```

Converts the Unix timestamp using a custom format.

## Aliases

This function has the following aliases:

- `unix-to-readable` - Converts a Unix timestamp to a human-readable date/time string.


## Source

Defined in: ../profile.d/conversion-modules/data/time/unix.ps1
