# Connect-Database

## Synopsis

Connects to a database using available client tools.

## Description

Provides a universal interface for connecting to various database types. Automatically detects available database client tools and uses the appropriate one.

## Signature

```powershell
Connect-Database
```

## Parameters

### -DatabaseType

Database type: PostgreSQL, MySQL, SQLite, MongoDB, SQLServer, Oracle.

### -ConnectionString

Database connection string or connection parameters.

### -Host

Database host name or IP address.

### -Port

Database port number.

### -Database

Database name.

### -Credential

PSCredential object containing username and password.

### -UseGui

Use GUI client if available (default: true).


## Outputs

System.Object. Connection information or process object.


## Examples

### Example 1

`powershell
$cred = Get-Credential
    Connect-Database -DatabaseType PostgreSQL -Host localhost -Database mydb -Credential $cred
    
    Connects to PostgreSQL database using GUI client.
``

### Example 2

`powershell
Connect-Database -DatabaseType MySQL -ConnectionString "mysql://user:pass@localhost:3306/mydb"
    
    Connects using connection string.
``

## Aliases

This function has the following aliases:

- `db-connect` - Connects to a database using available client tools.


## Source

Defined in: ..\profile.d\database.ps1
