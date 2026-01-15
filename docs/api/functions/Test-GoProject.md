# Test-GoProject

## Synopsis

Runs Go tests with common options.

## Description

Wrapper function for running Go tests. This runs 'go test' with common flags for verbose output and coverage.

## Signature

```powershell
Test-GoProject
```

## Parameters

### -VerboseOutput

Enable verbose test output (-v flag).

### -Coverage

Generate coverage report (-cover flag).

### -Arguments

Additional arguments to pass to go test. Can be used multiple times or as an array.


## Outputs

System.String. Output from go test execution.


## Examples

### Example 1

`powershell
Test-GoProject
        Runs tests in the current package.
``

### Example 2

`powershell
Test-GoProject -VerboseOutput
        Runs tests with verbose output.
``

### Example 3

`powershell
Test-GoProject -Coverage ./...
        Runs tests with coverage for all packages.
``

## Aliases

This function has the following aliases:

- `go-test-project` - Runs Go tests with common options.


## Source

Defined in: ..\profile.d\lang-go.ps1
