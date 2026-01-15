# Invoke-GitLeaksScan

## Synopsis

Scans a Git repository for secrets using gitleaks.

## Description

Runs gitleaks scan on the specified repository path. Gitleaks detects secrets, API keys, passwords, and other sensitive information in Git repositories.

## Signature

```powershell
Invoke-GitLeaksScan
```

## Parameters

### -RepositoryPath

Path to the Git repository to scan. Defaults to current directory.

### -OutputFormat

Output format: json, csv, sarif. Defaults to json.

### -ReportPath

Optional path to save the scan report.


## Outputs

System.String. Scan results in the specified format.


## Examples

### Example 1

`powershell
Invoke-GitLeaksScan -RepositoryPath "C:\Projects\MyRepo"
    
        Scans the specified repository for secrets.
``

### Example 2

`powershell
Invoke-GitLeaksScan -OutputFormat "sarif" -ReportPath "scan-results.sarif"
    
        Scans current directory and saves results in SARIF format.
``

## Aliases

This function has the following aliases:

- `gitleaks-scan` - Scans a Git repository for secrets using gitleaks.


## Source

Defined in: ..\profile.d\security-tools.ps1
