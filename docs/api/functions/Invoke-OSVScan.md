# Invoke-OSVScan

## Synopsis

Scans for vulnerabilities using OSV-Scanner.

## Description

Uses the OSV (Open Source Vulnerabilities) database to scan dependencies and identify known vulnerabilities in projects.

## Signature

```powershell
Invoke-OSVScan
```

## Parameters

### -Path

Path to the project to scan. Defaults to current directory.

### -OutputFormat

Output format: json, table. Defaults to table.


## Examples

### Example 1

`powershell
Invoke-OSVScan -Path "C:\Projects\MyProject"
    
        Scans the project for known vulnerabilities.
``

## Aliases

This function has the following aliases:

- `osv-scan` - Scans for vulnerabilities using OSV-Scanner.


## Source

Defined in: ..\profile.d\security-tools.ps1
