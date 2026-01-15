# Analyze-PE

## Synopsis

Analyzes PE (Portable Executable) files.

## Description

Analyzes Windows PE files (.exe, .dll) for metadata, imports, exports, and structure. Prefers pe-bear if available, falls back to exeinfo-pe or detect-it-easy.

## Signature

```powershell
Analyze-PE
```

## Parameters

### -InputFile

Path to the PE file to analyze.

### -OutputPath

File to save analysis results. Optional.

### -Detailed

Show detailed analysis information.


## Outputs

System.String. Analysis results or path to output file.


## Examples

### Example 1

`powershell
Analyze-PE -InputFile "app.exe"
        
        Analyzes a PE file and displays results.
``

## Source

Defined in: ..\profile.d\re-tools.ps1
