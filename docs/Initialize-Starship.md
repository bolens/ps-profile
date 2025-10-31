# Initialize-Starship

## Synopsis

Initializes the Starship prompt for PowerShell.

## Description

Sets up Starship as the PowerShell prompt if the starship command is available.
            Uses lazy initialization to avoid slowing down profile startup. Creates a global
            flag to ensure initialization happens only once per session.

## Signature

```powershell
Initialize-Starship
```

## Parameters

No parameters.

## Examples

No examples provided.

## Source

Defined in: profile.d\23-starship.ps1
