# Set-CloudProfile

## Synopsis

Sets cloud provider profile, account, or configuration.

## Description

Base function for managing cloud provider profiles/accounts/configurations. Handles environment variable setting and validation.

## Signature

```powershell
Set-CloudProfile
```

## Parameters

### -ProviderName

Provider name (e.g., 'aws', 'azure', 'gcloud').

### -ProfileType

Type of profile setting: 'Profile', 'Region', 'Account', 'Project', 'Config'.

### -Value

Value to set.

### -EnvVarName

Environment variable name to set (e.g., 'AWS_PROFILE', 'GCLOUD_PROJECT').

### -CommandName

CLI command name for validation.

### -DisplayName

Display name for the setting (e.g., 'AWS profile', 'GCloud project').

### -ValidateCommand

Optional command to validate the setting (e.g., 'aws sts get-caller-identity').


## Outputs

System.Boolean. True if successful, false otherwise.


## Examples

### Example 1

`powershell
Set-CloudProfile -ProviderName 'aws' -ProfileType 'Profile' -Value 'production' -EnvVarName 'AWS_PROFILE' -CommandName 'aws' -DisplayName 'AWS profile'
        
        Sets AWS profile to 'production'.
``

## Source

Defined in: ../profile.d/bootstrap/CloudProviderBase.ps1
