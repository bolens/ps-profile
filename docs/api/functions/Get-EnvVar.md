# Get-EnvVar

## Synopsis

Gets an environment variable value.

## Description

Retrieves a persisted user or machine environment variable using the .NET API. Falls back to the current process environment when no persisted value exists.

## Signature

```powershell
Get-EnvVar
```

## Parameters

### -Name

The name of the environment variable to retrieve. Type: [string]. Should be a valid environment variable name.

### -Global

If specified, retrieves the machine-wide value; otherwise, the user value.


## Outputs

String. The environment variable value, or null if not found.


## Examples

No examples provided.

## Source

Defined in: ../profile.d/utilities-modules/system/utilities-env.ps1
