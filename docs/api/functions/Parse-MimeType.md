# Parse-MimeType

## Synopsis

Parses a MIME type into its components.

## Description

Parses a MIME type string (type/subtype; parameter=value) into its components.

## Signature

```powershell
Parse-MimeType
```

## Parameters

### -MimeType

The MIME type string to parse.


## Outputs

PSCustomObject Returns an object with properties: Type, Subtype, Parameters, Extensions.


## Examples

### Example 1

`powershell
Parse-MimeType -MimeType "application/json; charset=utf-8"
    
    Parses MIME type and returns components.
``

### Example 2

`powershell
"text/html" | Parse-MimeType
    
    Parses MIME type from pipeline.
``

## Aliases

This function has the following aliases:

- `parse-mime` - Parses a MIME type into its components.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-mime-types.ps1
