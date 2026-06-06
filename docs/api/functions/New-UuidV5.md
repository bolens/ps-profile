# New-UuidV5

## Synopsis

Generates a UUID v5 (name-based).

## Description

Generates a UUID v5 from a namespace and name using SHA-1 hashing. Requires Node.js and uuid package.

## Signature

```powershell
New-UuidV5
```

## Parameters

### -Namespace

The namespace UUID (e.g., DNS, URL namespace).

### -Name

The name to generate UUID from.


## Outputs

System.String The generated UUID v5 string.


## Examples

### Example 1

`powershell
New-UuidV5 -Namespace "6ba7b810-9dad-11d1-80b4-00c04fd430c8" -Name "example.com"
    Generates a UUID v5 for the given namespace and name.
``

## Aliases

This function has the following aliases:

- `uuid-v5` - Generates a UUID v5 (name-based).


## Source

Defined in: ../profile.d/dev-tools-modules/data/uuid.ps1
