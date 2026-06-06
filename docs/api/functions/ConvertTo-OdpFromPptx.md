# ConvertTo-OdpFromPptx

## Synopsis

Converts PPTX file to ODP.

## Description

Uses pandoc to convert a Microsoft PowerPoint PPTX file to ODP (OpenDocument Presentation) format.

## Signature

```powershell
ConvertTo-OdpFromPptx
```

## Parameters

### -InputPath

Path to the input PPTX file.

### -OutputPath

Path for the output ODP file. If not specified, uses input path with .odp extension.


## Examples

### Example 1

`powershell
ConvertTo-OdpFromPptx -InputPath "presentation.pptx" -OutputPath "presentation.odp"
``

## Aliases

This function has the following aliases:

- `pptx-to-odp` - Converts PPTX file to ODP.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odp.ps1
