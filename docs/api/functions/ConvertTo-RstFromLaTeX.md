# ConvertTo-RstFromLaTeX

## Synopsis

Converts LaTeX file to RST.

## Description

Uses pandoc to convert a LaTeX file to reStructuredText (RST) format.

## Signature

```powershell
ConvertTo-RstFromLaTeX
```

## Parameters

### -InputPath

The path to the LaTeX file.

### -OutputPath

The path for the output RST file. If not specified, uses input path with .rst extension.


## Examples

### Example 1

```powershell
ConvertTo-RstFromLaTeX -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `latex-to-rst` - Converts LaTeX file to RST.


## Source

Defined in: ../profile.d/conversion-modules/document/document-latex.ps1
