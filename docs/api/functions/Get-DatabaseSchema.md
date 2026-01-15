# Get-DatabaseSchema

## Synopsis

Gets database schema information.

## Description

Retrieves schema information (tables, columns, indexes, etc.) from a database. Supports PostgreSQL, MySQL, SQLite, and MongoDB.

## Signature

```powershell
Get-DatabaseSchema
```

## Parameters

### -DatabaseType

Database type: PostgreSQL, MySQL, SQLite, MongoDB.

### -Database

Database name or connection string.

### -TableName

Optional specific table name to get schema for.

### -OutputFormat

Output format: table, json. Defaults to table.


## Outputs

System.Object. Schema information.


## Examples

### Example 1

`powershell
Get-DatabaseSchema -DatabaseType PostgreSQL -Database mydb
    
    Gets schema for all tables in PostgreSQL database.
``

### Example 2

`powershell
Get-DatabaseSchema -DatabaseType MySQL -Database mydb -TableName users -OutputFormat json
    
    Gets schema for specific table in JSON format.
``

## Aliases

This function has the following aliases:

- `db-schema` - Gets database schema information.


## Source

Defined in: ..\profile.d\database.ps1
