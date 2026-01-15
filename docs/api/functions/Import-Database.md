# Import-Database

## Synopsis

Imports a database from a file.

## Description

Imports database schema and/or data from a file using database-specific tools. Supports PostgreSQL, MySQL, SQLite, and MongoDB.

## Signature

```powershell
Import-Database
```

## Parameters

### -DatabaseType

Database type: PostgreSQL, MySQL, SQLite, MongoDB.

### -Database

Target database name.

### -InputPath

Path to input file.


## Outputs

System.Boolean. True if import successful.


## Examples

### Example 1

`powershell
Import-Database -DatabaseType PostgreSQL -Database mydb -InputPath "backup.sql"
    
    Imports PostgreSQL database from SQL file.
``

### Example 2

`powershell
Import-Database -DatabaseType MongoDB -Database mydb -InputPath "backup.json"
    
    Imports MongoDB data from JSON file.
``

## Aliases

This function has the following aliases:

- `db-import` - Imports a database from a file.


## Source

Defined in: ..\profile.d\database.ps1
