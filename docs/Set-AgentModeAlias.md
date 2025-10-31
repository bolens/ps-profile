# Set-AgentModeAlias

## Synopsis

Creates collision-safe aliases for profile fragments.

## Description

Defines a helper function that creates aliases or function wrappers
        without overwriting existing user or module commands. Used by profile fragments
        to safely register aliases.

## Signature

```powershell
Set-AgentModeAlias
```

## Parameters

### -Name

The name of the alias to create.

### -Target

The target command for the alias.

## Examples

No examples provided.

## Source

Defined in: profile.d\00-bootstrap.ps1
