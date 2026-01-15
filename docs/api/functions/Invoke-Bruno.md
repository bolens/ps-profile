# Invoke-Bruno

## Synopsis

Runs Bruno API collections.

## Description

Executes Bruno API collections for testing REST APIs. Bruno is a lightweight, fast, and modern API client.

## Signature

```powershell
Invoke-Bruno
```

## Parameters

### -CollectionPath

Path to the Bruno collection file or directory. If not specified, uses current directory.

### -Environment

Environment name to use for the collection.


## Outputs

System.String. Output from Bruno execution.


## Examples

### Example 1

`powershell
Invoke-Bruno -CollectionPath "./api-collection"
        Runs the Bruno collection in the specified directory.
``

### Example 2

`powershell
Invoke-Bruno -Environment "production"
        Runs the Bruno collection using the production environment.
``

## Aliases

This function has the following aliases:

- `bruno` - Runs Bruno API collections.


## Source

Defined in: ..\profile.d\api-tools.ps1
