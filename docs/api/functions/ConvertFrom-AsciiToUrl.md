# ConvertFrom-AsciiToUrl

## Synopsis

Converts ASCII text to URL/percent encoded representation.

## Description

Converts ASCII text to URL/percent encoded string representation following RFC 3986 specification.

## Signature

```powershell
ConvertFrom-AsciiToUrl
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.


## Outputs

System.String The URL/percent encoded representation of the input text.


## Examples

### Example 1

```powershell
"Hello World" | ConvertFrom-AsciiToUrl
```

Converts "Hello World" to "Hello%20World".

### Example 2

```powershell
ConvertFrom-AsciiToUrl -InputObject "test@example.com"
```

Converts to URL encoding.

## Aliases

This function has the following aliases:

- `ascii-to-url` - Converts ASCII text to URL/percent encoded representation.
- `url-encode` - Converts ASCII text to URL/percent encoded representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
