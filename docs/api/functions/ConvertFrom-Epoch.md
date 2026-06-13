# ConvertFrom-Epoch

## Synopsis

Converts Unix timestamp to DateTime.

## Description

Converts a Unix timestamp (seconds since epoch) to a local DateTime.

## Signature

```powershell
ConvertFrom-Epoch
```

## Parameters

### -epoch

Unix timestamp in seconds since 1970-01-01 UTC.


## Examples

### Example 1

```powershell
ConvertFrom-Epoch -epoch 1700000000
```

## Aliases

This function has the following aliases:

- `epoch-to-date` - Converts Unix epoch timestamp to DateTime.
- `from-epoch` - Converts Unix epoch timestamp to DateTime.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-datetime.ps1
