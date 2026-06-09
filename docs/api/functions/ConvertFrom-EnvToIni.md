# ConvertFrom-EnvToIni

## Synopsis

Converts a .env file to INI format.

## Description

Converts a .env file to INI format. All key-value pairs are placed in an [env] section.

## Signature

```powershell
ConvertFrom-EnvToIni
```

## Parameters

### -InputPath

The path to the .env file.

### -OutputPath

The path for the output INI file. If not specified, uses input path with .ini extension.


## Outputs

System.String Returns the path to the output INI file.


## Examples

### Example 1

```powershell
ConvertFrom-EnvToIni -InputPath '.env'
```

Converts .env to .env.ini.

## Aliases

This function has the following aliases:

- `env-to-ini` - Converts a .env file to INI format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/env.ps1
