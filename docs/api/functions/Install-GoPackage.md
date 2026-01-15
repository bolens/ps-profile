# Install-GoPackage

## Synopsis

Installs Go packages globally.

## Description

Installs packages as global binaries using go install.

## Signature

```powershell
Install-GoPackage
```

## Parameters

### -Packages

Package paths to install (e.g., github.com/user/cmd/tool@latest).


## Examples

### Example 1

`powershell
Install-GoPackage github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    Installs golangci-lint globally.
``

## Source

Defined in: ..\profile.d\go.ps1
