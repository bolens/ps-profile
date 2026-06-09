# ConvertTo-JwtFromJson

## Synopsis

Converts JSON file to JWT token.

## Description

Reads JSON from a file and creates a JWT token with the JSON data as payload. Requires Node.js and jsonwebtoken package.

## Signature

```powershell
ConvertTo-JwtFromJson
```

## Parameters

### -InputPath

The path to the JSON file.

### -OutputPath

The path for the output JWT token file. If not specified, uses input path with .jwt extension.

### -Secret

Optional secret key for signing the token. If not provided, uses default secret.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

```powershell
ConvertTo-JwtFromJson -InputPath "payload.json" -Secret "mysecret"
```

Converts payload.json to payload.jwt token.

## Aliases

This function has the following aliases:

- `json-to-jwt` - Converts JSON file to JWT token.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-jwt.ps1
