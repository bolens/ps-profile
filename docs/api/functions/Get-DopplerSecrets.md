# Get-DopplerSecrets

## Synopsis

Retrieves secrets from Doppler.

## Description

Gets secrets from Doppler secrets management service. Supports different output formats and project/config selection.

## Signature

```powershell
Get-DopplerSecrets
```

## Parameters

### -Project

Doppler project name.

### -Config

Doppler config name (e.g., dev, staging, prod).

### -Secret

Specific secret name to retrieve. If not specified, returns all secrets.

### -OutputFormat

Output format: json, env, shell. Defaults to env.


## Outputs

System.String. Secret values in the specified format.


## Examples

### Example 1

`powershell
Get-DopplerSecrets -Project "my-project" -Config "dev"
        
        Gets all secrets from the specified project and config.
``

### Example 2

`powershell
Get-DopplerSecrets -Project "my-project" -Config "prod" -Secret "API_KEY"
        
        Gets a specific secret value.
``

## Source

Defined in: ..\profile.d\cloud-enhanced.ps1
