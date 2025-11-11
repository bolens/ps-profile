# Get-EnvVar

## Synopsis

Gets an environment variable value from the registry.

## Description

Retrieves the value of an environment variable from the Windows registry. Works with both user and system-wide environment variables.

## Signature

```powershell
Get-EnvVar
```

## Parameters

### -Name

The name of the environment variable to retrieve. Type: [string]. Should be a valid environment variable name.

### -Global

If specified, retrieves from system-wide registry; otherwise, from user registry.


## Outputs

String. The environment variable value, or null if not found.


## Examples

No examples provided.

## Source

Defined in: profile.d\05-utilities.ps1
