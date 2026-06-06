# ConvertFrom-DjvuToText

## Synopsis

Extracts text from DjVu file.

## Description

Extracts text content from a DjVu document file using djvutxt tool.

## Signature

```powershell
ConvertFrom-DjvuToText
```

## Parameters

### -InputPath

The path to the DjVu file (.djvu or .djv extension).

### -OutputPath

The path for the output text file. If not specified, uses input path with .txt extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-DjvuToText -InputPath "document.djvu"
    
    Extracts text from document.djvu to document.txt.
``

## Aliases

This function has the following aliases:

- `djvu-to-text` - Extracts text from DjVu file.


## Source

Defined in: ../profile.d/conversion-modules/document/document-djvu.ps1
