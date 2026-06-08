# New-Uuid

## Synopsis

Generates a UUID (Universally Unique Identifier).

## Description

Generates a UUID of the specified version. Supports v1 (time-based) and v4 (random). Note: v1 uses a simplified implementation. For true time-based UUIDs, use external libraries.

## Signature

```powershell
New-Uuid
```

## Parameters

### -Version

The UUID version to generate. Default is v4 (random).


## Outputs

System.String The generated UUID string.


## Examples

### Example 1

`powershell
New-Uuid
    Generates a random UUID v4.
``

### Example 2

`powershell
New-Uuid -Version v1
    Generates a time-based UUID v1 (simplified).
``

## Aliases

This function has the following aliases:

- `guid` - Generates a new UUID (GUID).
- `uuid` - Generates a new UUID (GUID).


## Source

Defined in: ../profile.d/dev-tools-modules/data/uuid.ps1
