# Backup-Database

## Synopsis

Creates a backup of a database.

## Description

Creates a backup of a database using database-specific backup tools. Supports PostgreSQL, MySQL, SQLite, and MongoDB.

## Signature

```powershell
Backup-Database
```

## Parameters

### -DatabaseType

Database type: PostgreSQL, MySQL, SQLite, MongoDB.

### -Database

Database name or connection string.

### -BackupPath

Path to backup file. Defaults to database name with timestamp.

### -Compress

Compress the backup file.


## Outputs

System.String. Path to backup file.


## Examples

### Example 1

`powershell
Backup-Database -DatabaseType PostgreSQL -Database mydb
    
    Creates a PostgreSQL backup.
``

### Example 2

`powershell
Backup-Database -DatabaseType MySQL -Database mydb -BackupPath "backup.sql" -Compress
    
    Creates a compressed MySQL backup.
``

## Aliases

This function has the following aliases:

- `db-backup` - Creates a backup of a database.


## Source

Defined in: ..\profile.d\database.ps1
