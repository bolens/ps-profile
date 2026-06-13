# Initialize-FileConversion-DatabaseAccess

## Synopsis

Initializes Microsoft Access database format conversion utility functions.

## Description

Sets up internal conversion functions for Microsoft Access database formats (.mdb, .accdb). MDB is the older Access format, ACCDB is the newer format. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-DatabaseAccess
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Python with pyodbc or mdb-tools (for MDB) to be installed. On Windows, may also use Microsoft Access Database Engine (ACE).


## Source

Defined in: ../profile.d/conversion-modules/data/database/database-access.ps1
