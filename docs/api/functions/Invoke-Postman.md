# Invoke-Postman

## Synopsis

Runs Postman collections using Newman CLI.

## Description

Executes Postman collections using Newman, the command-line companion for Postman. Newman allows you to run and test Postman collections from the command line.

## Signature

```powershell
Invoke-Postman
```

## Parameters

### -CollectionPath

Path to the Postman collection file (JSON). Can be a local file path or a Postman collection URL.

### -Environment

Path to Postman environment file (JSON).

### -Reporters

Reporters to use for output (cli, json, html, junit). Can be used multiple times.

### -OutputFile

Output file path for reports.


## Outputs

System.String. Output from Newman execution.


## Examples

### Example 1

`powershell
Invoke-Postman -CollectionPath "./collection.json"
        Runs the Postman collection.
``

### Example 2

`powershell
Invoke-Postman -CollectionPath "./collection.json" -Environment "./env.json" -Reporters "html", "json"
        Runs the collection with environment and generates HTML and JSON reports.
``

## Aliases

This function has the following aliases:

- `postman` - Runs Postman collections using Newman CLI.


## Source

Defined in: ..\profile.d\api-tools.ps1
