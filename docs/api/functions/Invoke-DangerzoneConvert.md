# Invoke-DangerzoneConvert

## Synopsis

Converts potentially dangerous documents to safe PDFs using Dangerzone.

## Description

Uses Dangerzone to convert PDFs, Office documents, and images to safe PDFs by rendering them in a sandboxed environment.

## Signature

```powershell
Invoke-DangerzoneConvert
```

## Parameters

### -InputPath

Path to the document to convert.

### -OutputPath

Optional output path for the safe PDF. Defaults to input path with .safe.pdf extension.


## Examples

### Example 1

`powershell
Invoke-DangerzoneConvert -InputPath "C:\Downloads\document.pdf"
    
        Converts the document to a safe PDF.
``

## Aliases

This function has the following aliases:

- `dangerzone-convert` - Converts potentially dangerous documents to safe PDFs using Dangerzone.


## Source

Defined in: ..\profile.d\security-tools.ps1
