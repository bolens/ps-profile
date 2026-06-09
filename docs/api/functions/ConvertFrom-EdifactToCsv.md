# ConvertFrom-EdifactToCsv

## Synopsis

Converts EDIFACT file to CSV format.

## Description

Converts an EDIFACT file to a simplified CSV format where each segment becomes a row. Format: Segment,Element1,Element2,Element3,Element4,Element5

## Signature

```powershell
ConvertFrom-EdifactToCsv
```

## Parameters

### -InputPath

The path to the EDIFACT file (.edifact, .edi, or .edf extension).

### -OutputPath

The path for the output CSV file. If not specified, uses input path with .csv extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertFrom-EdifactToCsv -InputPath "message.edifact"
```

Converts message.edifact to message.csv.

## Aliases

This function has the following aliases:

- `edifact-to-csv` - Converts EDIFACT file to CSV format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edifact.ps1
