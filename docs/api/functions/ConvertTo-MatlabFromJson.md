# ConvertTo-MatlabFromJson

## Synopsis

Converts JSON file to MATLAB .mat format.

## Description

Converts a JSON file to MATLAB .mat format. Requires Python with scipy package to be installed.

## Signature

```powershell
ConvertTo-MatlabFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output MATLAB .mat file. If not specified, uses input path with .mat extension.


## Examples

### Example 1

`powershell
ConvertTo-MatlabFromJson -InputPath ./input.file
``

## Aliases

This function has the following aliases:

- `json-to-mat` - Converts JSON file to MATLAB .mat format.
- `json-to-matlab` - Converts JSON file to MATLAB .mat format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-matlab.ps1
