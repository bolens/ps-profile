# Decode-Jwt

## Synopsis

Decodes a JSON Web Token (JWT).

## Description

Decodes a JWT token and returns the header and payload as objects. Does not verify the signature, only decodes the token structure.

## Signature

```powershell
Decode-Jwt
```

## Parameters

### -Token

The JWT token string to decode.


## Outputs

PSCustomObject Object containing Header, Payload, and Signature properties.


## Examples

### Example 1

`powershell
Decode-Jwt -Token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    Decodes the JWT token and displays header and payload.
``

## Aliases

This function has the following aliases:

- `jwt-decode` - Decodes a JSON Web Token (JWT).


## Source

Defined in: ../profile.d/dev-tools-modules/crypto/jwt.ps1
