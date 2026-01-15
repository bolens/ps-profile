# Lint-GoProject

## Synopsis

Lints Go code using golangci-lint.

## Description

Wrapper function for golangci-lint, a fast linter for Go code that runs multiple linters in parallel.

## Signature

```powershell
Lint-GoProject
```

## Parameters

### -Arguments

Additional arguments to pass to golangci-lint. Can be used multiple times or as an array.


## Outputs

System.String. Output from golangci-lint execution.


## Examples

### Example 1

`powershell
Lint-GoProject
        Lints the current Go project.
``

### Example 2

`powershell
Lint-GoProject --fix
        Lints and automatically fixes issues where possible.
``

### Example 3

`powershell
Lint-GoProject ./...
        Lints all packages recursively.
``

## Aliases

This function has the following aliases:

- `golangci-lint` - Lints Go code using golangci-lint.


## Source

Defined in: ..\profile.d\lang-go.ps1
