# Invoke-ClamAVScan

## Synopsis

Scans files or directories using ClamAV.

## Description

Uses ClamAV antivirus engine to scan for malware and viruses.

## Signature

```powershell
Invoke-ClamAVScan
```

## Parameters

### -Path

Path to file or directory to scan.

### -Recursive

Scan directories recursively.

### -Quarantine

Move infected files to quarantine directory.


## Examples

### Example 1

`powershell
Invoke-ClamAVScan -Path "C:\Downloads" -Recursive
    
        Recursively scans the Downloads directory for malware.
``

## Aliases

This function has the following aliases:

- `clamav-scan` - Scans files or directories using ClamAV.


## Source

Defined in: ..\profile.d\security-tools.ps1
