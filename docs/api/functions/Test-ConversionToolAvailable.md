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

System.Boolean. True if tool is available, false otherwise.


## Examples

### Example 1

```powershell
Test-ConversionToolAvailable -ToolCommand 'value' -InstallHint 'value'
```

## Source

Defined in: ../profile.d/conversion-modules/helpers/ConversionBase.ps1
