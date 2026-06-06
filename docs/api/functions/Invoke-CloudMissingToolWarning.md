# Invoke-CloudMissingToolWarning

## Synopsis

Base module providing common patterns for cloud provider CLI wrappers.

## Description

Extracts common patterns from AWS, Azure, and GCloud modules to reduce duplication. Provides abstract functions that cloud-specific modules can use or extend. Common Patterns: 1. Command execution with tool detection 2. Profile/account/configuration management 3. Resource listing with JSON parsing 4. Credential management and connection testing 5. Error handling and output formatting

## Signature

```powershell
Invoke-CloudMissingToolWarning
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is a base module. Cloud-specific modules (aws.ps1, azure.ps1, gcloud.ps1) should use these functions or extend them with provider-specific logic.


## Source

Defined in: ../profile.d/bootstrap/CloudProviderBase.ps1
