# Switch-AwsAccount

## Synopsis

Switches AWS account/profile quickly.

## Description

A convenience function that combines setting profile and testing connection. Sets the AWS profile and verifies connectivity.

## Signature

```powershell
Switch-AwsAccount
```

## Parameters

### -ProfileName

Name of the AWS profile to switch to.

### -SkipTest

Skip connection test after switching.


## Outputs

System.Boolean. True if switch and test (if not skipped) are successful.


## Examples

### Example 1

`powershell
Switch-AwsAccount -ProfileName "production"
    
    Switches to production profile and tests connection.
``

### Example 2

`powershell
Switch-AwsAccount -ProfileName "dev" -SkipTest
    
    Switches to dev profile without testing connection.
``

## Aliases

This function has the following aliases:

- `aws-switch` - Switches AWS account/profile quickly.


## Source

Defined in: ..\profile.d\aws.ps1
