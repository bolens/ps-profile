# Encode-Jwt

## Synopsis

Encodes data into a JSON Web Token (JWT).

## Description

Creates a JWT token from a payload and optional header. Requires Node.js and jsonwebtoken package.

## Signature

```powershell
Encode-Jwt
```

## Parameters

### -Payload

Hashtable containing the JWT payload data.

### -Header

Hashtable containing the JWT header. Default includes alg and typ.

### -Secret

Secret key for signing the token.


## Outputs

System.String The encoded JWT token string.


## Examples

### Example 1

```powershell
Encode-Jwt -Payload @{sub="user123"; exp=1234567890} -Secret "mysecret"
```

Creates a JWT token with the specified payload.

## Aliases

This function has the following aliases:

- `jwt-encode` - Encodes data into a JSON Web Token (JWT).


## Source

Defined in: ../profile.d/dev-tools-modules/crypto/jwt.ps1
