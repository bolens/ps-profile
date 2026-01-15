# Invoke-Insomnia

## Synopsis

Runs Insomnia API requests or collections.

## Description

Executes Insomnia API requests or collections using the Insomnia CLI. Insomnia is a powerful API client with support for REST, GraphQL, gRPC, and more.

## Signature

```powershell
Invoke-Insomnia
```

## Parameters

### -CollectionPath

Path to the Insomnia collection file or directory. If not specified, uses current directory.

### -Environment

Environment name to use for the collection.


## Outputs

System.String. Output from Insomnia execution.


## Examples

### Example 1

`powershell
Invoke-Insomnia -CollectionPath "./api-collection"
        Runs the Insomnia collection in the specified directory.
``

### Example 2

`powershell
Invoke-Insomnia -Environment "production"
        Runs the Insomnia collection using the production environment.
``

## Aliases

This function has the following aliases:

- `insomnia` - Runs Insomnia API requests or collections.


## Source

Defined in: ..\profile.d\api-tools.ps1
