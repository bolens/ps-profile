# ConvertFrom-JwtToJson

## Synopsis

Converts JWT token file to JSON format.

## Description

Decodes a JWT token from a file and converts it to structured JSON format with header, payload, and signature. Note: This does not verify the signature, only decodes the token structure.

## Signature

```powershell
ConvertFrom-JwtToJson
```

## Parameters

### -InputPath

The path to the JWT token file (.jwt or .token extension).

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Outputs

None. Creates output file at specified or default path.


## Examples

### Example 1

`powershell
ConvertFrom-JwtToJson -InputPath "token.jwt"
    
    Decodes token.jwt to token.json.
``

## Aliases

This function has the following aliases:

- `jwt-to-json` - Converts JWT token file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/specialized/specialized-jwt.ps1
