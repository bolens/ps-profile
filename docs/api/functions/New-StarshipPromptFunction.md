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

No parameters.

## Examples

No examples provided.

## Source

Defined in: ..\profile.d\23-starship.ps1
