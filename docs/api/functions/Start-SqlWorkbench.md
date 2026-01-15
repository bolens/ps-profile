# Start-SqlWorkbench

## Synopsis

Launches SQL Workbench/J.

## Description

Opens SQL Workbench/J, a universal database tool for SQL databases. Supports multiple database systems including MySQL, PostgreSQL, Oracle, and more.

## Signature

```powershell
Start-SqlWorkbench
```

## Parameters

### -Workspace

Optional workspace file to open.


## Outputs

System.Diagnostics.Process. Process object for SQL Workbench/J.


## Examples

### Example 1

`powershell
Start-SqlWorkbench
        Launches SQL Workbench/J.
``

### Example 2

`powershell
Start-SqlWorkbench -Workspace "C:\Workspaces\my-workspace.xml"
        Launches SQL Workbench/J with a specific workspace.
``

## Aliases

This function has the following aliases:

- `sql-workbench` - Launches SQL Workbench/J.


## Source

Defined in: ..\profile.d\database-clients.ps1
