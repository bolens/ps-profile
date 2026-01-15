# Invoke-NetworkScan

## Synopsis

Performs network scanning using available tools.

## Description

Uses sniffnet or trippy for network scanning and diagnostics. Supports different scan types and output formats.

## Signature

```powershell
Invoke-NetworkScan
```

## Parameters

### -Target

Target host or network to scan (IP address or CIDR).

### -Tool

Tool to use: sniffnet or trippy. Defaults to sniffnet.

### -OutputFormat

Output format: text, json. Defaults to text.


## Examples

### Example 1

`powershell
Invoke-NetworkScan -Target "192.168.1.0/24"
        
        Scans the specified network using sniffnet.
``

### Example 2

`powershell
Invoke-NetworkScan -Target "192.168.1.1" -Tool "trippy"
        
        Performs network diagnostics on the target using trippy.
``

## Source

Defined in: ..\profile.d\network-analysis.ps1
