# Merge-Pdf

## Synopsis

Merges multiple PDF files.

## Description

Uses pdftk to combine multiple PDF files into one.

## Signature

```powershell
Merge-Pdf
```

## Parameters

### -InputPaths

Array of paths to PDF files to merge.

### -OutputPath

The path for the output merged PDF file.


## Examples

### Example 1

```powershell
Merge-Pdf -InputPaths @() -OutputPath ./output.file
```

## Aliases

This function has the following aliases:

- `pdf-merge` - Merges multiple PDF files.


## Source

Defined in: ../profile.d/conversion-modules/media/pdf.ps1
