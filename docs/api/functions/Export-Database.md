# Export-Database

## Synopsis

Exports a database to a file.

## Description

Exports database schema and/or data to a file using database-specific tools. Supports PostgreSQL, MySQL, SQLite, and MongoDB.

## Signature

```powershell
Export-Database
```

## Parameters

### -DatabaseType

Database type: PostgreSQL, MySQL, SQLite, MongoDB.

### -Database

Database name or connection string.

### -OutputPath

Path to output file.

### -SchemaOnly

Export only schema (no data).

### -DataOnly

Export only data (no schema).


## Outputs

System.String. Path to exported file.


## Examples

### Example 1

`powershell
Export-Database -DatabaseType PostgreSQL -Database mydb -OutputPath "backup.sql"
    
    Exports PostgreSQL database to SQL file.
``

### Example 2

`powershell
Export-Database -DatabaseType MongoDB -Database mydb -OutputPath "backup.json" -DataOnly
    
    Exports MongoDB data to JSON file.
``

## Aliases

This function has the following aliases:

- `db-export` - Exports a database to a file.


## Source

Defined in: ..\profile.d\database.ps1
