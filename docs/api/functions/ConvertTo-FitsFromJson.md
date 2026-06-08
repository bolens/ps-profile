# ConvertTo-FitsFromJson

## Synopsis

Converts JSON file to FITS format.

## Description

Converts a JSON file to FITS (Flexible Image Transport System) format. Requires Python with astropy package to be installed.

## Signature

```powershell
ConvertTo-FitsFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output FITS file. If not specified, uses input path with .fits extension.


## Examples

### Example 1

```powershell
ConvertTo-FitsFromJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `json-to-fit` - Converts JSON file to FITS format.
- `json-to-fits` - Converts JSON file to FITS format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-fits.ps1
