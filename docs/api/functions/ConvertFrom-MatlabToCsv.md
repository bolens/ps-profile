# ConvertFrom-MatlabToCsv

## Synopsis

Converts MATLAB .mat file to CSV format.

## Description

Converts a MATLAB .mat file to CSV format. Extracts a variable from the .mat file and writes it to CSV. Requires Python with scipy package to be installed.

## Signature

```powershell
ConvertFrom-MatlabToCsv
```

## Parameters

### -InputPath

The path to the MATLAB .mat file.

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.

### -VariableName

Optional. Name of the variable to extract. If not specified, uses the first non-metadata variable.


## Examples

### Example 1

```powershell
ConvertFrom-MatlabToCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `mat-to-csv` - Converts MATLAB .mat file to CSV format.
- `matlab-to-csv` - Converts MATLAB .mat file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-matlab.ps1
