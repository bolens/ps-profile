# ConvertTo-OdtFromDocx

## Synopsis

Converts DOCX file to ODT.

## Description

Uses pandoc to convert a Microsoft Word DOCX file to ODT (OpenDocument Text) format.

## Signature

```powershell
ConvertTo-OdtFromDocx
```

## Parameters

### -InputPath

Path to the input DOCX file.

### -OutputPath

Path for the output ODT file. If not specified, uses input path with .odt extension.


## Examples

### Example 1

```powershell
ConvertTo-OdtFromDocx -InputPath "document.docx" -OutputPath "document.odt"
```

## Aliases

This function has the following aliases:

- `docx-to-odt` - Converts DOCX file to ODT.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-odt.ps1
