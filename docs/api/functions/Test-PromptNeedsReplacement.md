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

No parameters.

## Examples

No examples provided.

## Source

Defined in: ..\profile.d\23-starship.ps1
