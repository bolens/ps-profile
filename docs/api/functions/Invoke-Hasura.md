# Invoke-Hasura

## Synopsis

Executes Hasura CLI commands.

## Description

Wrapper function for Hasura CLI that executes Hasura GraphQL engine commands. Hasura provides instant GraphQL APIs over databases.

## Signature

```powershell
Invoke-Hasura
```

## Parameters

### -Arguments

Arguments to pass to hasura-cli command. Can be used multiple times or as an array.


## Outputs

System.String. Output from Hasura CLI execution.


## Examples

### Example 1

`powershell
Invoke-Hasura version
        Checks Hasura CLI version.
``

### Example 2

`powershell
Invoke-Hasura migrate apply
        Applies database migrations.
``

### Example 3

`powershell
Invoke-Hasura console
        Starts Hasura console.
``

## Aliases

This function has the following aliases:

- `hasura` - Executes Hasura CLI commands.


## Source

Defined in: ../profile.d/database-clients.ps1
