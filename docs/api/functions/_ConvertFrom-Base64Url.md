# _ConvertFrom-Base64Url

## Synopsis

Initializes JWT utility functions.

## Description

Sets up internal JWT encoding and decoding functions. This function is called automatically by Ensure-DevTools.

## Signature

```powershell
_ConvertFrom-Base64Url [String]$Base64Url
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Node.js and jsonwebtoken package for encoding.


## Source

Defined in: ../profile.d/dev-tools-modules/crypto/jwt.ps1
