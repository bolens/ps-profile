# Set-EnvVar

## Synopsis

Sets an environment variable value.

## Description

Sets a persisted user or machine environment variable using the .NET API and updates the current process environment. On Windows, broadcasts the change.

## Signature

```powershell
Set-EnvVar
```

## Parameters

### -Name

The name of the environment variable. Type: [string]. Should be a valid environment variable name.

### -Value

The value to set. If null or empty, the variable is removed. Type: [string]. Can be null or empty to remove the variable.

### -Global

If specified, sets the machine-wide value; otherwise, the user value.


## Outputs

None. This function does not return a value.


## Examples

No examples provided.

## Source

Defined in: ../profile.d/utilities-modules/system/utilities-env.ps1
