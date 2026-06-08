# Get-TextHash

## Synopsis

Calculates cryptographic hash of text input.

## Description

Computes the hash value of text using the specified cryptographic algorithm. Supports MD5, SHA1, SHA256, SHA384, and SHA512 algorithms.

## Signature

```powershell
Get-TextHash
```

## Parameters

### -Text

The text to hash. Can be piped.

### -Algorithm

The hash algorithm to use. Default is SHA256.


## Outputs

PSCustomObject Object containing Algorithm, Hash, and Text properties.


## Examples

### Example 1

```powershell
"Hello World" | Get-TextHash
```

Calculates SHA256 hash of "Hello World".

### Example 2

```powershell
"password" | Get-TextHash -Algorithm MD5
```

Calculates MD5 hash of "password".

## Aliases

This function has the following aliases:

- `text-hash` - Calculates cryptographic hash of text input.


## Source

Defined in: ../profile.d/dev-tools-modules/crypto/hash.ps1
