# Build-GoProject

## Synopsis

Builds a Go project with common optimizations.

## Description

Wrapper function for building Go projects. This runs 'go build' with common flags for production builds.

## Signature

```powershell
Build-GoProject
```

## Parameters

### -Output

Output binary name or path (optional).

### -Arguments

Additional arguments to pass to go build. Can be used multiple times or as an array.


## Outputs

System.String. Output from go build execution.


## Examples

### Example 1

`powershell
Build-GoProject
        Builds the current Go project.
``

### Example 2

`powershell
Build-GoProject -Output myapp
        Builds and names the output binary 'myapp'.
``

### Example 3

`powershell
Build-GoProject -Arguments @('-ldflags', '-s -w')
        Builds with linker flags to strip symbols.
``

## Aliases

This function has the following aliases:

- `go-build-project` - Builds a Go project with common optimizations.


## Source

Defined in: ..\profile.d\lang-go.ps1
