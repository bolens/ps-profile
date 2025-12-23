# Invoke-GCloud

## Synopsis

Executes Google Cloud CLI commands.

## Description

Wrapper function for Google Cloud CLI that checks for command availability before execution.

## Signature

```powershell
Invoke-GCloud
```

## Parameters

### -Arguments

Arguments to pass to gcloud.


## Examples

### Example 1

`powershell
Invoke-GCloud --version
``

### Example 2

`powershell
Invoke-GCloud config list
``

## Aliases

This function has the following aliases:

- `gcloud` - Executes Google Cloud CLI commands.


## Source

Defined in: ..\profile.d\51-gcloud.ps1
