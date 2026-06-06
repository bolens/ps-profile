# Parse-HttpHeaders

## Synopsis

Parses HTTP headers into a hashtable.

## Description

Parses HTTP headers (Header-Name: value format) into a hashtable. Supports multi-line header values and multiple headers with the same name.

## Signature

```powershell
Parse-HttpHeaders
```

## Parameters

### -Headers

The HTTP headers string to parse.


## Outputs

Hashtable Returns a hashtable with header names as keys and values.


## Examples

### Example 1

`powershell
$headers = @"
Content-Type: application/json
Authorization: Bearer token123
"@
    Parse-HttpHeaders -Headers $headers
    
    Parses headers and returns hashtable.
``

### Example 2

`powershell
Get-Content headers.txt | Parse-HttpHeaders
    
    Parses headers from pipeline.
``

## Aliases

This function has the following aliases:

- `parse-headers` - Parses HTTP headers into a hashtable.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-http-headers.ps1
