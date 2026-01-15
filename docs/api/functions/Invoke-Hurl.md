# Invoke-Hurl

## Synopsis

Executes Hurl test files.

## Description

Runs HTTP requests defined in Hurl test files. Hurl is a command-line tool that runs HTTP requests defined in a simple plain text format.

## Signature

```powershell
Invoke-Hurl
```

## Parameters

### -TestFile

Path to the Hurl test file (.hurl). If not specified, searches for .hurl files in current directory.

### -Variable

Set a variable for the test execution (can be used multiple times). Format: "name=value"

### -Output

Output file path for the response.


## Outputs

System.String. Output from Hurl execution.


## Examples

### Example 1

`powershell
Invoke-Hurl -TestFile "./api-tests.hurl"
        Runs the specified Hurl test file.
``

### Example 2

`powershell
Invoke-Hurl -TestFile "./test.hurl" -Variable "base_url=https://api.example.com"
        Runs the test with a variable set.
``

## Aliases

This function has the following aliases:

- `hurl` - Executes Hurl test files.


## Source

Defined in: ..\profile.d\api-tools.ps1
