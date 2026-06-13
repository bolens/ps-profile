# ConvertFrom-RtfToText

## Synopsis

Converts RTF file to Plain Text.

## Description

Uses pandoc to convert an RTF file to plain text format.

## Signature

```powershell
ConvertFrom-RtfToText
```

## Parameters

### -InputPath

Path to the input RTF file.

### -OutputPath

Path for the output text file. If not specified, uses input path with .txt extension.


## Examples

### Example 1

```powershell
ConvertFrom-RtfToText -InputPath "document.rtf" -OutputPath "document.txt"
```

## Aliases

This function has the following aliases:

- `rtf-to-text` - Converts RTF file to Plain Text.
- `rtf-to-txt` - Converts RTF file to Plain Text.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-rtf.ps1
