# Set-EnvVar

## Synopsis

Sets an environment variable value in the registry.

## Description

Sets the value of an environment variable in the Windows registry and broadcasts the change.

## Signature

```powershell
Set-EnvVar
```

## Parameters

### -Name

The name of the environment variable.

### -Value

The value to set. If null or empty, the variable is removed.

### -Global

If specified, sets the variable in the system-wide registry; otherwise, in user registry.

## Examples

No examples provided.

## Source

Defined in: profile.d\05-utilities.ps1
