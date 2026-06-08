# ConvertFrom-PlainTextToDocx

## Synopsis

Converts Plain Text file to DOCX.

## Description

Uses pandoc to convert a Plain Text file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertFrom-PlainTextToDocx
```

## Parameters

### -InputPath

Path to the input Plain Text file.

### -OutputPath

Path for the output DOCX file. If not specified, uses input path with .docx extension.

### -Encoding

Text encoding of the input file (default: UTF8).


## Examples

### Example 1

```powershell
ConvertFrom-PlainTextToDocx -InputPath "document.txt" -OutputPath "document.docx"
```

## Aliases

This function has the following aliases:

- `text-to-docx` - Converts Plain Text file to DOCX.
- `txt-to-docx` - Converts Plain Text file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-plaintext.ps1
