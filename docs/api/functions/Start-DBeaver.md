# Start-DBeaver

## Synopsis

Launches DBeaver Universal Database Tool.

## Description

Opens DBeaver, a universal database tool that supports many database types. DBeaver provides a rich SQL editor, data viewer, and database management features.

## Signature

```powershell
Start-DBeaver
```

## Parameters

### -Workspace

Optional workspace directory to open.


## Outputs

System.Diagnostics.Process. Process object for DBeaver.


## Examples

### Example 1

`powershell
Start-DBeaver
        Launches DBeaver.
``

### Example 2

`powershell
Start-DBeaver -Workspace "C:\Workspaces\dbeaver"
        Launches DBeaver with a specific workspace directory.
``

## Aliases

This function has the following aliases:

- `dbeaver` - Launches DBeaver Universal Database Tool.


## Source

Defined in: ..\profile.d\database-clients.ps1
