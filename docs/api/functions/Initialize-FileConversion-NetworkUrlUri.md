# Initialize-FileConversion-NetworkUrlUri

## Synopsis

Initializes URL/URI parsing and conversion utility functions.

## Description

Sets up internal conversion functions for URL/URI parsing and conversion. Supports parsing URLs/URIs into components (scheme, host, path, query, fragment) and converting between formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-NetworkUrlUri
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. URL/URI format follows RFC 3986 specification. Components: scheme://[userinfo@]host[:port][/path][?query][#fragment]


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-url-uri.ps1
