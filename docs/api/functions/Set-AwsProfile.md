# Set-AwsProfile

## Synopsis

Sets the AWS profile environment variable.

## Description

Sets the AWS_PROFILE environment variable to the specified profile name.

## Signature

```powershell
Set-AwsProfile
```

## Parameters

### -ProfileName

Name of the AWS profile to use.


## Examples

### Example 1

`powershell
Set-AwsProfile -ProfileName "production"
``

### Example 2

`powershell
Set-AwsProfile -ProfileName "development"
``

## Aliases

This function has the following aliases:

- `aws-profile` - Sets the AWS profile environment variable.


## Source

Defined in: ..\profile.d\31-aws.ps1
