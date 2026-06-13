# Test-PromptNeedsReplacement

## Synopsis

Checks if a prompt function needs replacement.

## Description

Module-scoped prompts can break when modules are unloaded, so we replace them with direct function calls to the starship executable for reliability.

## Signature

```powershell
Test-PromptNeedsReplacement
```

## Parameters

### -PromptCmd

The prompt function to check.


## Outputs

System.Boolean


## Examples

### Example 1

```powershell
Test-PromptNeedsReplacement -PromptCmd 'value'
```

## Source

Defined in: ../profile.d/starship/StarshipHelpers.ps1
