# Get-AwsCredentials

## Synopsis

Lists configured AWS credential profiles.

## Description

Retrieves a list of all configured AWS profiles from the credentials file. Shows profile names and optionally their access key IDs.

## Signature

```powershell
Get-AwsCredentials
```

## Parameters

### -ShowKeys

Show access key IDs (partially masked) for each profile.


## Outputs

System.Object[]. Array of profile information objects.


## Examples

### Example 1

`powershell
Get-AwsCredentials
    
    Lists all configured AWS profiles.
``

### Example 2

`powershell
Get-AwsCredentials -ShowKeys
    
    Lists profiles with partially masked access key IDs.
``

## Aliases

This function has the following aliases:

- `aws-credentials` - Lists configured AWS credential profiles.


## Source

Defined in: ..\profile.d\aws.ps1
