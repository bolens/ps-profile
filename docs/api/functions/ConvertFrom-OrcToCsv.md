# ConvertFrom-OrcToCsv

## Synopsis

Converts Apache ORC file to CSV format.

## Description

Converts an Apache ORC file to CSV format. Requires Python with pyarrow package to be installed.

## Signature

```powershell
ConvertFrom-OrcToCsv
```

## Parameters

### -InputPath

The path to the ORC file (.orc extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

`powershell
ConvertFrom-OrcToCsv -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `orc-to-csv` - Converts Apache ORC file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-orc.ps1
