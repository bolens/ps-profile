# Build-UrlUri

## Synopsis

Builds a URL/URI from components.

## Description

Constructs a URL/URI string from a hashtable or object containing URL components.

## Signature

```powershell
Build-UrlUri
```

## Parameters

### -Components

Hashtable or object with URL components: Scheme, Host, Port, Path, Query, Fragment, QueryParameters.


## Outputs

System.String Returns the constructed URL/URI string.


## Examples

### Example 1

```powershell
$components = @{
```

Scheme = 'https' Host = 'example.com' Path = '/api/users' QueryParameters = @{ id = '123' } } Build-UrlUri -Components $components Builds URL from components.

## Aliases

This function has the following aliases:

- `build-uri` - Builds a URL/URI from components.
- `build-url` - Builds a URL/URI from components.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-url-uri.ps1
