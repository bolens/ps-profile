# ConvertTo-Epoch

## Synopsis

Converts DateTime to Unix timestamp.

## Description

Converts a DateTime object or string to a Unix timestamp (seconds since epoch).

## Signature

```powershell
ConvertTo-Epoch
```

## Parameters

### -date

DateTime value to convert. Defaults to the current local time.


## Examples

### Example 1

`powershell
ConvertTo-Epoch -date (Get-Date '2024-01-01')
.PARAMETER date
    DateTime value to convert. Defaults to the current local time.
``

## Aliases

This function has the following aliases:

- `date-to-epoch` - Converts DateTime to Unix epoch timestamp.
- `to-epoch` - Converts DateTime to Unix epoch timestamp.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-datetime.ps1
