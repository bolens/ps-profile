# Test-ConversionToolAvailable

## Synopsis

Tests if a conversion tool is available.

## Description

Checks for conversion tool availability with optional installation hint.

## Signature

```powershell
Test-ConversionToolAvailable
```

## Parameters

### -ToolCommand

Name of the tool command to check.

### -InstallHint

Installation hint to display if tool is missing.


## Outputs

System.Boolean. True if tool is available, false otherwise. .EXAMPLE Test-ConversionToolAvailable


## Examples

### Example 1

`powershell
Test-ConversionToolAvailable
``

## Source

Defined in: ../profile.d/conversion-modules/helpers/ConversionBase.ps1
