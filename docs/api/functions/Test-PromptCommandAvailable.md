# Test-PromptCommandAvailable

## Synopsis

Tests if a prompt framework command is available.

## Description

Checks for prompt framework command availability with optional installation hint.

## Signature

```powershell
Test-PromptCommandAvailable
```

## Parameters

### -CommandName

Name of the command to check.

### -InstallHint

Installation hint to display if command is missing.


## Outputs

System.Boolean. True if command is available, false otherwise.


## Examples

### Example 1

```powershell
Test-PromptCommandAvailable -CommandName 'Get-GitStatus' -InstallHint 'value'
```

## Source

Defined in: ../profile.d/bootstrap/PromptBase.ps1
