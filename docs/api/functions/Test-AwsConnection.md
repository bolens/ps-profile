# Test-AwsConnection

## Synopsis

Tests AWS connectivity and credentials.

## Description

Verifies that AWS CLI can connect to AWS and that credentials are valid. Uses sts get-caller-identity to test authentication.

## Signature

```powershell
Test-AwsConnection
```

## Parameters

### -Profile

Optional AWS profile to test. Uses current profile if not specified.


## Outputs

System.Boolean. True if connection is successful, false otherwise.


## Examples

### Example 1

`powershell
Test-AwsConnection
    
    Tests connectivity with the current AWS profile.
``

### Example 2

`powershell
Test-AwsConnection -Profile "production"
    
    Tests connectivity with the specified profile.
``

## Aliases

This function has the following aliases:

- `aws-test` - Tests AWS connectivity and credentials.


## Source

Defined in: ..\profile.d\aws.ps1
