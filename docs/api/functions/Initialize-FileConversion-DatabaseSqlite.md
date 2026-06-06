# Initialize-FileConversion-DatabaseSqlite

## Synopsis

Initializes SQLite database format conversion utility functions.

## Description

Sets up internal conversion functions for SQLite database format. SQLite is a lightweight, file-based SQL database engine. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-DatabaseSqlite
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires SQLite command-line tool (sqlite3) or .NET System.Data.SQLite to be installed.


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-sqlite.ps1
