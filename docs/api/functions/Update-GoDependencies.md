# Update-GoDependencies

## Synopsis

Updates all module dependencies in the current Go project.

## Description

Runs go get -u ./... to upgrade dependencies to their latest minor/patch versions.

## Signature

```powershell
Update-GoDependencies
```

## Parameters

No parameters.

## Examples

### Example 1

```powershell
Update-GoDependencies
```

Updates all dependencies in the current module.

## Aliases

This function has the following aliases:

- `go-update` - Updates all module dependencies in the current Go project.


## Source

Defined in: ../profile.d/lang-go-basic.ps1
