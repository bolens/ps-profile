# Invoke-TruffleHogScan

## Synopsis

Scans for secrets using TruffleHog.

## Description

Runs TruffleHog scan to detect secrets, API keys, and credentials using pattern matching and entropy analysis.

## Signature

```powershell
Invoke-TruffleHogScan
```

## Parameters

### -Path

Path to scan (file, directory, or Git repository). Defaults to current directory.

### -OutputFormat

Output format: json, yaml. Defaults to json.


## Examples

### Example 1

`powershell
Invoke-TruffleHogScan -Path "C:\Projects\MyRepo"
    
        Scans the specified path for secrets.
``

## Aliases

This function has the following aliases:

- `trufflehog-scan` - Scans for secrets using TruffleHog.


## Source

Defined in: ..\profile.d\security-tools.ps1
