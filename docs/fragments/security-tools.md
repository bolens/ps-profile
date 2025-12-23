# Security Tools Fragment

## Overview

The `security-tools.ps1` fragment provides wrapper functions for security scanning and analysis tools. It includes functions for secret scanning, vulnerability detection, malware analysis, and safe document viewing.

**Tier:** Standard  
**Dependencies:** bootstrap, env

## Functions

### Invoke-GitLeaksScan

Scans Git repositories for secrets and sensitive information using Gitleaks.

**Alias:** `gitleaks-scan`

**Parameters:**
- `RepositoryPath` (string, optional): Path to the Git repository. Defaults to current directory.
- `OutputFormat` (string, optional): Output format (json, csv, sarif). Defaults to json.
- `ReportPath` (string, optional): Path to save the report file.
- `NoGit` (switch): Scan files without Git history.

**Examples:**
```powershell
# Scan current repository
Invoke-GitLeaksScan

# Scan specific repository with JSON output
Invoke-GitLeaksScan -RepositoryPath "C:\Projects\MyRepo" -OutputFormat json

# Scan without Git history
Invoke-GitLeaksScan -NoGit -ReportPath "C:\reports\scan.json"
```

### Invoke-TruffleHogScan

Scans for secrets using TruffleHog with pattern detection.

**Alias:** `trufflehog-scan`

**Parameters:**
- `Path` (string, optional): Path to scan. Defaults to current directory.
- `OutputFormat` (string, optional): Output format (json, text). Defaults to json.

**Examples:**
```powershell
# Scan current directory
Invoke-TruffleHogScan

# Scan specific path
Invoke-TruffleHogScan -Path "C:\Projects" -OutputFormat json
```

### Invoke-OSVScan

Scans for vulnerabilities using the OSV (Open Source Vulnerabilities) database.

**Alias:** `osv-scan`

**Parameters:**
- `Path` (string, optional): Path to scan. Defaults to current directory.
- `OutputFormat` (string, optional): Output format (json, table). Defaults to json.

**Examples:**
```powershell
# Scan current directory for vulnerabilities
Invoke-OSVScan

# Scan with table output
Invoke-OSVScan -Path "C:\Projects" -OutputFormat table
```

### Invoke-YaraScan

Scans files using YARA rules for malware detection and pattern matching.

**Alias:** `yara-scan`

**Parameters:**
- `FilePath` (string, mandatory): Path to the file to scan.
- `Rules` (string, mandatory): Path to YARA rules file or directory.

**Examples:**
```powershell
# Scan a file with YARA rules
Invoke-YaraScan -FilePath "C:\Downloads\file.exe" -Rules "C:\rules\malware.yar"

# Scan with rules directory
Invoke-YaraScan -FilePath "C:\Downloads\file.exe" -Rules "C:\rules"
```

### Invoke-ClamAVScan

Scans files and directories for malware using ClamAV antivirus.

**Alias:** `clamav-scan`

**Parameters:**
- `Path` (string, mandatory): Path to scan (file or directory).

**Examples:**
```powershell
# Scan a directory
Invoke-ClamAVScan -Path "C:\Downloads"

# Scan a specific file
Invoke-ClamAVScan -Path "C:\Downloads\file.exe"
```

### Invoke-DangerzoneConvert

Converts potentially dangerous documents (PDFs, Office documents, images) to safe PDFs using Dangerzone.

**Alias:** `dangerzone`

**Parameters:**
- `InputPath` (string, mandatory): Path to the document to convert.
- `OutputPath` (string, optional): Output path for the safe PDF. Defaults to input path with `.safe.pdf` extension.

**Examples:**
```powershell
# Convert a document to safe PDF
Invoke-DangerzoneConvert -InputPath "C:\Downloads\document.pdf"

# Convert with custom output path
Invoke-DangerzoneConvert -InputPath "C:\Downloads\document.pdf" -OutputPath "C:\Safe\document-safe.pdf"
```

## Installation

All tools are optional and gracefully degrade when not installed. Install hints are provided when tools are missing.

**Installation via Scoop:**
```powershell
scoop install gitleaks
scoop install trufflehog
scoop install osv-scanner
scoop install yara
scoop install clamav
scoop install dangerzone
```

## Error Handling

All functions:
- Return `$null` when tools are not available
- Display installation hints when tools are missing
- Handle command execution errors gracefully
- Validate input paths before execution

## Testing

Comprehensive test coverage:
- **Unit tests:** 119/132 passing (90.2% coverage)
- **Integration tests:** 20/20 passing
- **Performance tests:** 5/5 passing

Test files:
- `tests/unit/profile-security-tools-*.tests.ps1` (8 test files)
- `tests/integration/tools/security-tools.tests.ps1`
- `tests/performance/security-tools-performance.tests.ps1`

## Notes

- All functions use `Test-CachedCommand` for efficient command availability checks
- Functions support pipeline input where appropriate
- Output formats vary by tool (JSON, CSV, SARIF, text, table)
- Functions use `&` operator to bypass alias resolution and prevent recursion

