# Set-AgentModeFunction

## Synopsis

Creates collision-safe functions for profile fragments.

## Description

Defines a helper function that creates small convenience functions or wrappers
        without overwriting existing user or module commands. Used by profile fragments
        to safely register functions.

## Signature

```powershell
Set-AgentModeFunction
```

## Parameters

### -Name

The name of the function to create.

### -Body

The script block containing the function body.

## Examples

No examples provided.

## Source

Defined in: profile.d\00-bootstrap.ps1
