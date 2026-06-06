# Get-ExtensionFromMimeType

## Synopsis

Gets file extension(s) from a MIME type.

## Description

Returns the file extension(s) associated with a given MIME type.

## Signature

```powershell
Get-ExtensionFromMimeType
```

## Parameters

### -MimeType

The MIME type string.


## Outputs

System.String[] or System.String Returns the file extension(s), or empty array if not found.


## Examples

### Example 1

`powershell
Get-ExtensionFromMimeType -MimeType "application/json"
    
    Returns "json".
``

### Example 2

`powershell
"image/png" | Get-ExtensionFromMimeType
    
    Returns "png" from pipeline.
``

## Aliases

This function has the following aliases:

- `ext-from-mime` - Gets file extension(s) from a MIME type.


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-mime-types.ps1
