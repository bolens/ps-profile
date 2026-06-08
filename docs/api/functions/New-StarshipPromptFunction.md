# New-StarshipPromptFunction

## Synopsis

Creates a global prompt function that directly calls starship executable.

## Description

Creates a prompt function that calls starship directly (bypassing module scope issues). This ensures the prompt continues working even if the Starship module is unloaded.

## Signature

```powershell
New-StarshipPromptFunction
```

## Parameters

### -StarshipCommandPath

The path to the starship executable.


## Examples

### Example 1

`powershell
New-StarshipPromptFunction
``

## Source

Defined in: ../profile.d/starship/StarshipPrompt.ps1
