# Invoke-YaraScan

## Synopsis

Scans files using YARA rules.

## Description

Uses YARA to scan files against pattern rules for malware detection and threat hunting.

## Signature

```powershell
Invoke-YaraScan
```

## Parameters

### -FilePath

Path to the file or directory to scan.

### -RulesPath

Path to YARA rules file or directory.

### -Recursive

Scan directories recursively.


## Examples

### Example 1

`powershell
Invoke-YaraScan -FilePath "C:\Downloads\file.exe" -RulesPath "C:\Rules\malware.yar"
    
        Scans the file against the specified YARA rules.
``

## Aliases

This function has the following aliases:

- `yara-scan` - Scans files using YARA rules.


## Source

Defined in: ..\profile.d\security-tools.ps1
