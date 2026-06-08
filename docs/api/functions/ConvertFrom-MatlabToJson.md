# ConvertFrom-MatlabToJson

## Synopsis

Converts MATLAB .mat file to JSON format.

## Description

Converts a MATLAB .mat file to JSON format. MATLAB .mat files store variables and data structures. Requires Python with scipy package to be installed.

## Signature

```powershell
ConvertFrom-MatlabToJson
```

## Parameters

### -InputPath

The path to the MATLAB .mat file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-MatlabToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `mat-to-json` - Converts MATLAB .mat file to JSON format.
- `matlab-to-json` - Converts MATLAB .mat file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-matlab.ps1
