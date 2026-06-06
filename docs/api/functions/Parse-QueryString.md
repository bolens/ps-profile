# Parse-QueryString

## Synopsis

Parses a query string into a hashtable.

## Description

Parses a URL query string (key1=value1&key2=value2) into a hashtable with decoded keys and values. Supports multiple values for the same key.

## Signature

```powershell
Parse-QueryString
```

## Parameters

### -QueryString

The query string to parse (with or without leading ?).


## Outputs

Hashtable Returns a hashtable with query parameters as keys and values.


## Examples

### Example 1

`powershell
Parse-QueryString -QueryString "name=John&age=30&city=New York"
    
    Parses query string and returns hashtable.
``

### Example 2

`powershell
"key1=value1&key2=value2" | Parse-QueryString
    
    Parses query string from pipeline.
``

## Aliases

This function has the following aliases:

- `parse-query` - Parses a query string into a hashtable.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-query-string.ps1
