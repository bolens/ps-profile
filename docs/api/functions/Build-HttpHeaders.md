# Build-HttpHeaders

## Synopsis

Builds HTTP headers from a hashtable.

## Description

Constructs HTTP headers string from a hashtable or object containing header name-value pairs.

## Signature

```powershell
Build-HttpHeaders
```

## Parameters

### -Headers

Hashtable or object with HTTP headers.


## Outputs

System.String Returns the constructed HTTP headers string.


## Examples

### Example 1

```powershell
$headers = @{
```

'Content-Type' = 'application/json' 'Authorization' = 'Bearer token123' } Build-HttpHeaders -Headers $headers Builds headers string from hashtable.

## Aliases

This function has the following aliases:

- `build-headers` - Builds HTTP headers from a hashtable.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-http-headers.ps1
