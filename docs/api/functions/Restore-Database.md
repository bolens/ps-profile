# Restore-Database

## Synopsis

Restores a database from a backup.

## Description

Restores a database from a backup file using database-specific restore tools. Supports PostgreSQL, MySQL, SQLite, and MongoDB.

## Signature

```powershell
Restore-Database
```

## Parameters

### -DatabaseType

Database type: PostgreSQL, MySQL, SQLite, MongoDB.

### -Database

Target database name.

### -BackupPath

Path to backup file.


## Outputs

System.Boolean. True if restore successful.


## Examples

### Example 1

`powershell
Restore-Database -DatabaseType PostgreSQL -Database mydb -BackupPath "backup.dump"
    
    Restores PostgreSQL database from backup.
``

### Example 2

`powershell
Restore-Database -DatabaseType MySQL -Database mydb -BackupPath "backup.sql.gz"
    
    Restores MySQL database from compressed backup.
``

## Aliases

This function has the following aliases:

- `db-restore` - Restores a database from a backup.


## Source

Defined in: ..\profile.d\database.ps1
