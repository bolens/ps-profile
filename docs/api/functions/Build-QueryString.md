# Build-QueryString

## Synopsis

Builds a query string from a hashtable.

## Description

Constructs a URL query string from a hashtable or object containing key-value pairs.

## Signature

```powershell
Build-QueryString
```

## Parameters

### -Parameters

Hashtable or object with query parameters.


## Outputs

System.String Returns the constructed query string.


## Examples

### Example 1

```powershell
$params = @{
```

name = 'John' age = '30' city = 'New York' } Build-QueryString -Parameters $params Builds query string from parameters.

## Aliases

This function has the following aliases:

- `build-query` - Builds a query string from a hashtable.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-query-string.ps1
