# ConvertTo-DocxFromFb2

## Synopsis

Converts FB2 file to DOCX.

## Description

Uses pandoc to convert a FictionBook (FB2) e-book file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertTo-DocxFromFb2
```

## Parameters

### -InputPath

The path to the FB2 file (.fb2 or .fbz extension).

### -OutputPath

The path for the output DOCX file. If not specified, uses input path with .docx extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-DocxFromFb2 -InputPath "book.fb2"
```

Converts book.fb2 to book.docx.

## Aliases

This function has the following aliases:

- `fb2-to-docx` - Converts FB2 file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-fb2.ps1
