# Get-OutputPathFromInput

## Synopsis

Generates an output path from an input path by replacing the extension.

## Description

Creates an output file path by replacing the input file's extension with a new extension.

## Signature

```powershell
Get-OutputPathFromInput
```

## Parameters

### -InputPath

Path to the input file.

### -OutputExtension

New extension for the output file (e.g., '.html', '.pdf').

### -InputExtension

Optional input extension to replace. If not provided, uses file's actual extension.


## Outputs

System.String. Generated output path.


## Examples

### Example 1

`powershell
Get-OutputPathFromInput -InputPath 'document.md' -OutputExtension '.html'
        
        Returns 'document.html'.
``

## Source

Defined in: ../profile.d/conversion-modules/helpers/ConversionBase.ps1
