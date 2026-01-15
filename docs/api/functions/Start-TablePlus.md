# Start-TablePlus

## Synopsis

Launches TablePlus.

## Description

Opens TablePlus, a modern database client with a clean interface. TablePlus supports multiple database systems with a unified interface.

## Signature

```powershell
Start-TablePlus
```

## Parameters

### -Connection

Optional connection name or file to open.


## Outputs

System.Diagnostics.Process. Process object for TablePlus.


## Examples

### Example 1

`powershell
Start-TablePlus
        Launches TablePlus.
``

### Example 2

`powershell
Start-TablePlus -Connection "my-connection"
        Launches TablePlus with a specific connection.
``

## Aliases

This function has the following aliases:

- `tableplus` - Launches TablePlus.


## Source

Defined in: ..\profile.d\database-clients.ps1
