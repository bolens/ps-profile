# ConvertFrom-FitsToCsv

## Synopsis

Converts FITS file to CSV format.

## Description

Converts a FITS (Flexible Image Transport System) file to CSV format. Extracts table data from FITS HDUs and writes to CSV. Requires Python with astropy package to be installed.

## Signature

```powershell
ConvertFrom-FitsToCsv
```

## Parameters

### -InputPath

The path to the FITS file (.fits or .fit extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Examples

### Example 1

```powershell
ConvertFrom-FitsToCsv -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `fit-to-csv` - Converts FITS file to CSV format.
- `fits-to-csv` - Converts FITS file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-fits.ps1
