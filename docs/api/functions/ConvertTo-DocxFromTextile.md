# ConvertTo-DocxFromTextile

## Synopsis

Converts Textile file to DOCX.

## Description

Uses pandoc to convert a Textile file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertTo-DocxFromTextile
```

## Parameters

### -InputPath

The path to the Textile file (.textile or .tx extension).

### -OutputPath

The path for the output DOCX file. If not specified, uses input path with .docx extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-DocxFromTextile -InputPath "document.textile"
```

Converts document.textile to document.docx.

## Aliases

This function has the following aliases:

- `textile-to-docx` - Converts Textile file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-textile.ps1
