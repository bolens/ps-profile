# Initialize-StarshipModule

## Synopsis

Ensures Starship module stays loaded to prevent prompt from breaking.

## Description

Stores a reference to the Starship module globally to prevent it from being garbage collected. This helps maintain prompt functionality even if the module would otherwise be unloaded.

## Signature

```powershell
Initialize-StarshipModule
```

## Parameters

No parameters.

## Examples

No examples provided.

## Source

Defined in: ..\profile.d\23-starship.ps1
