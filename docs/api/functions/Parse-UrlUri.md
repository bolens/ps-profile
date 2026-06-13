# Parse-UrlUri

## Synopsis

Parses a URL/URI into its components.

## Description

Parses a URL/URI string into its components (scheme, host, port, path, query, fragment, etc.) and returns a structured object with all components.

## Signature

```powershell
Parse-UrlUri
```

## Parameters

### -Url

The URL/URI string to parse.


## Outputs

PSCustomObject Returns an object with properties: Scheme, Host, Port, Path, Query, Fragment, QueryParameters, etc.


## Examples

### Example 1

```powershell
Parse-UrlUri -Url "https://example.com:8080/path?key=value#fragment"
```

Parses the URL and returns components.

### Example 2

```powershell
"https://example.com/path" | Parse-UrlUri
```

Parses URL from pipeline.

## Aliases

This function has the following aliases:

- `parse-uri` - Parses a URL/URI into its components.
- `parse-url` - Parses a URL/URI into its components.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-url-uri.ps1
