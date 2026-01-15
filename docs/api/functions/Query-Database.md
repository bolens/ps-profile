# Query-Database

## Synopsis

Executes a database query.

## Description

Executes a SQL or database query using available command-line tools. Supports PostgreSQL, MySQL, SQLite, and MongoDB.

## Signature

```powershell
Query-Database
```

## Parameters

### -DatabaseType

Database type: PostgreSQL, MySQL, SQLite, MongoDB.

### -Query

SQL query or database command to execute.

### -Database

Database name or connection string.

### -OutputFormat

Output format: table, json, csv. Defaults to table.


## Outputs

System.Object. Query results.


## Examples

### Example 1

`powershell
Query-Database -DatabaseType PostgreSQL -Database mydb -Query "SELECT * FROM users LIMIT 10"
    
    Executes a PostgreSQL query.
``

### Example 2

`powershell
Query-Database -DatabaseType MongoDB -Database mydb -Query "db.users.find().limit(10)"
    
    Executes a MongoDB query.
``

## Aliases

This function has the following aliases:

- `db-query` - Executes a database query.


## Source

Defined in: ..\profile.d\database.ps1
