# Get-MimeTypeFromExtension

## Synopsis

Gets MIME type from a file extension.

## Description

Returns the MIME type associated with a given file extension.

## Signature

```powershell
Get-MimeTypeFromExtension
```

## Parameters

### -Extension

The file extension (with or without leading dot).


## Outputs

System.String Returns the MIME type string, or empty string if not found.


## Examples

### Example 1

```powershell
Get-MimeTypeFromExtension -Extension "json"
```

Returns "application/json".

### Example 2

```powershell
".html" | Get-MimeTypeFromExtension
```

Returns "text/html" from pipeline.

## Aliases

This function has the following aliases:

- `mime-from-ext` - Gets MIME type from a file extension.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-mime-types.ps1
