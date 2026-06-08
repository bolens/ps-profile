# Clear-IsbnCache

## Synopsis

Clears cached ISBN lookup results.

## Description

Removes cached provider responses under the profile ISBN cache directory.

## Signature

```powershell
Clear-IsbnCache
```

## Parameters

### -LookupIsbn

Optional ISBN to clear. When omitted, clears the entire ISBN cache directory.

### -Provider

Provider scope for a single ISBN cache entry. Defaults to Auto.


## Examples

### Example 1

```powershell
Clear-IsbnCache -Isbn 'value' -Provider 'value'
```

### Example 2

```powershell
Clear-IsbnCache -LookupIsbn '9780306406157'
```

## Aliases

This function has the following aliases:

- `isbn-cache-clear` - Clears cached ISBN lookup results.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn.ps1
