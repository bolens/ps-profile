# Export-AwsCredentials

## Synopsis

Exports AWS credentials to environment variables.

## Description

Exports AWS credentials from a profile to environment variables. Useful for scripts that need AWS credentials but don't use profiles.

## Signature

```powershell
Export-AwsCredentials
```

## Parameters

### -Profile

AWS profile name to export. Uses current profile if not specified.

### -ExportToEnv

Export to environment variables (default). If false, only displays values.


## Outputs

System.Object. Credential information object.


## Examples

### Example 1

`powershell
Export-AwsCredentials -Profile "production"
    
    Exports production profile credentials to environment variables.
``

### Example 2

`powershell
Export-AwsCredentials -Profile "dev" -ExportToEnv:$false
    
    Displays credentials without exporting them.
``

## Source

Defined in: ..\profile.d\aws.ps1
