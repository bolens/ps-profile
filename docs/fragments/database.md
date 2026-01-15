# Database Module

## Overview

The `database.ps1` module provides comprehensive database management functions for connecting to, querying, exporting, importing, backing up, and restoring various database types. It supports PostgreSQL, MySQL, SQLite, MongoDB, SQL Server, and Oracle databases.

## Functions

### Connect-Database

Connects to a database using available client tools (GUI or CLI).

**Parameters:**

- `DatabaseType` (Mandatory): Database type - PostgreSQL, MySQL, SQLite, MongoDB, SQLServer, Oracle
- `ConnectionString` (Optional): Database connection string
- `Host` (Optional): Database host name or IP address
- `Port` (Optional): Database port number
- `Database` (Optional): Database name
- `Credential` (Optional): PSCredential object containing username and password
- `UseGui` (Switch): Use GUI client if available (default: true)

**Examples:**

```powershell
# Connect to PostgreSQL using credentials
$cred = Get-Credential
Connect-Database -DatabaseType PostgreSQL -Host localhost -Database mydb -Credential $cred

# Connect using connection string
Connect-Database -DatabaseType MySQL -ConnectionString "mysql://user:pass@localhost:3306/mydb"

# Connect to SQLite database
Connect-Database -DatabaseType SQLite -Database "C:\data\mydb.db"
```

**Supported Tools:**

- PostgreSQL: DBeaver (GUI), psql (CLI)
- MySQL: DBeaver (GUI), mysql (CLI)
- SQLite: DBeaver (GUI), sqlite3 (CLI)
- MongoDB: MongoDB Compass (GUI), mongosh (CLI)

### Query-Database

Executes a database query using available command-line tools.

**Parameters:**

- `DatabaseType` (Mandatory): Database type - PostgreSQL, MySQL, SQLite, MongoDB
- `Query` (Mandatory): SQL query or database command to execute
- `Database` (Optional): Database name or connection string
- `OutputFormat` (Optional): Output format - table, json, csv (default: table)

**Examples:**

```powershell
# Execute PostgreSQL query
Query-Database -DatabaseType PostgreSQL -Database mydb -Query "SELECT * FROM users LIMIT 10"

# Execute MongoDB query
Query-Database -DatabaseType MongoDB -Database mydb -Query "db.users.find().limit(10)"

# Get results in JSON format
Query-Database -DatabaseType PostgreSQL -Database mydb -Query "SELECT * FROM users" -OutputFormat json
```

**Supported Tools:**

- PostgreSQL: psql
- MySQL: mysql
- SQLite: sqlite3
- MongoDB: mongosh

### Export-Database

Exports a database to a file (schema and/or data).

**Parameters:**

- `DatabaseType` (Mandatory): Database type - PostgreSQL, MySQL, SQLite, MongoDB
- `Database` (Mandatory): Database name or connection string
- `OutputPath` (Mandatory): Path to output file
- `SchemaOnly` (Switch): Export only schema (no data)
- `DataOnly` (Switch): Export only data (no schema)

**Examples:**

```powershell
# Export full PostgreSQL database
Export-Database -DatabaseType PostgreSQL -Database mydb -OutputPath "backup.sql"

# Export schema only
Export-Database -DatabaseType PostgreSQL -Database mydb -OutputPath "schema.sql" -SchemaOnly

# Export data only
Export-Database -DatabaseType MySQL -Database mydb -OutputPath "data.sql" -DataOnly
```

**Supported Tools:**

- PostgreSQL: pg_dump
- MySQL: mysqldump
- SQLite: sqlite3
- MongoDB: mongoexport

### Import-Database

Imports data from a file into a database.

**Parameters:**

- `DatabaseType` (Mandatory): Database type - PostgreSQL, MySQL, SQLite, MongoDB
- `Database` (Mandatory): Database name
- `InputPath` (Mandatory): Path to input file (SQL dump, JSON, etc.)

**Examples:**

```powershell
# Import PostgreSQL dump
Import-Database -DatabaseType PostgreSQL -Database mydb -InputPath "backup.sql"

# Import MySQL dump
Import-Database -DatabaseType MySQL -Database mydb -InputPath "backup.sql"

# Import SQLite dump
Import-Database -DatabaseType SQLite -Database "mydb.db" -InputPath "backup.sql"
```

**Supported Tools:**

- PostgreSQL: psql
- MySQL: mysql
- SQLite: sqlite3
- MongoDB: mongoimport

### Backup-Database

Creates a backup of a database with automatic timestamp naming.

**Parameters:**

- `DatabaseType` (Mandatory): Database type - PostgreSQL, MySQL, SQLite, MongoDB
- `Database` (Mandatory): Database name
- `BackupPath` (Optional): Custom backup path (default: auto-generated with timestamp)
- `Compress` (Switch): Compress backup file using gzip

**Examples:**

```powershell
# Create automatic timestamped backup
Backup-Database -DatabaseType PostgreSQL -Database mydb

# Create compressed backup
Backup-Database -DatabaseType PostgreSQL -Database mydb -Compress

# Create backup with custom path
Backup-Database -DatabaseType MySQL -Database mydb -BackupPath "custom-backup.dump"
```

**Output:**
Returns the path to the created backup file.

### Restore-Database

Restores a database from a backup file.

**Parameters:**

- `DatabaseType` (Mandatory): Database type - PostgreSQL, MySQL, SQLite, MongoDB
- `Database` (Mandatory): Database name
- `BackupPath` (Mandatory): Path to backup file (supports .gz compressed files)

**Examples:**

```powershell
# Restore from SQL dump
Restore-Database -DatabaseType PostgreSQL -Database mydb -BackupPath "backup.sql"

# Restore from compressed backup
Restore-Database -DatabaseType PostgreSQL -Database mydb -BackupPath "backup.sql.gz"
```

**Returns:**
`$true` if restore succeeded, `$false` otherwise.

### Get-DatabaseSchema

Retrieves schema information for a database or specific table.

**Parameters:**

- `DatabaseType` (Mandatory): Database type - PostgreSQL, MySQL, SQLite, MongoDB
- `Database` (Mandatory): Database name
- `TableName` (Optional): Specific table name to get schema for
- `OutputFormat` (Optional): Output format - table, json (default: table)

**Examples:**

```powershell
# Get schema for all tables
Get-DatabaseSchema -DatabaseType PostgreSQL -Database mydb

# Get schema for specific table
Get-DatabaseSchema -DatabaseType MySQL -Database mydb -TableName users

# Get schema in JSON format
Get-DatabaseSchema -DatabaseType PostgreSQL -Database mydb -OutputFormat json
```

**Returns:**
Schema information including table names, column names, data types, nullability, and default values.

## Additional Functions

### Invoke-MongoDbCompass

Launches MongoDB Compass GUI.

**Example:**

```powershell
Invoke-MongoDbCompass
```

### Invoke-SqlWorkbench

Launches SQL Workbench/J.

**Example:**

```powershell
Invoke-SqlWorkbench
```

### Invoke-DBeaver

Launches DBeaver Universal Database Tool.

**Example:**

```powershell
Invoke-DBeaver
```

### Invoke-TablePlus

Launches TablePlus database management tool.

**Example:**

```powershell
Invoke-TablePlus
```

### Invoke-Hasura

Runs Hasura CLI commands.

**Example:**

```powershell
Invoke-Hasura console
Invoke-Hasura migrate apply
```

### Invoke-Supabase

Runs Supabase CLI commands.

**Example:**

```powershell
Invoke-Supabase status
Invoke-Supabase start
```

## Security

All functions that require authentication use `PSCredential` objects for secure credential handling. Passwords are stored as SecureString and never exposed in plain text.

**Example:**

```powershell
$cred = Get-Credential
Connect-Database -DatabaseType PostgreSQL -Host localhost -Database mydb -Credential $cred
```

## Error Handling

All functions include comprehensive error handling:

- Graceful degradation when tools are not available
- Clear error messages with installation hints
- Proper error propagation for debugging

## Installation

Required tools can be installed via Scoop:

```powershell
# PostgreSQL
scoop install postgresql

# MySQL
scoop install mysql

# MongoDB
scoop install mongodb-compass mongodb-database-tools

# SQLite
scoop install sqlite

# GUI Tools
scoop install dbeaver tableplus mongodb-compass
```

## Notes

- Functions automatically detect available tools and use the most appropriate one
- GUI tools are preferred when `UseGui` is enabled (default)
- CLI tools are used as fallback or when `UseGui` is disabled
- All functions support graceful degradation when tools are missing
- Connection strings can be used as an alternative to individual parameters
