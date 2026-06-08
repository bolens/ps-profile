# ConvertFrom-OdpToPptx

## Synopsis

Converts ODP file to PPTX.

## Description

Uses pandoc to convert an ODP file to Microsoft PowerPoint PPTX format.

## Signature

```powershell
ConvertFrom-OdpToPptx
```

## Parameters

### -InputPath

Path to the input ODP file.

### -OutputPath

Path for the output PPTX file. If not specified, uses input path with .pptx extension.


## Examples

### Example 1

```powershell
ConvertFrom-OdpToPptx -InputPath "presentation.odp" -OutputPath "presentation.pptx"
```

## Aliases

This function has the following aliases:

- `odp-to-pptx` - Converts ODP file to PPTX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odp.ps1
