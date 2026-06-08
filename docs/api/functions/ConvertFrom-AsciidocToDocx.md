# ConvertFrom-AsciidocToDocx

## Synopsis

Converts AsciiDoc file to DOCX.

## Description

Uses pandoc to convert an AsciiDoc file to Microsoft Word DOCX format.

## Signature

```powershell
ConvertFrom-AsciidocToDocx
```

## Parameters

### -InputPath

Path to the input AsciiDoc file.

### -OutputPath

Path for the output DOCX file. If not specified, uses input path with .docx extension.


## Examples

### Example 1

```powershell
ConvertFrom-AsciidocToDocx -InputPath "document.adoc" -OutputPath "document.docx"
```

## Aliases

This function has the following aliases:

- `adoc-to-docx` - Converts AsciiDoc file to DOCX.
- `asciidoc-to-docx` - Converts AsciiDoc file to DOCX.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-asciidoc.ps1
