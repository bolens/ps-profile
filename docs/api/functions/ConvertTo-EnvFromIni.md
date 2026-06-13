# ConvertTo-EnvFromIni

## Synopsis

Converts an INI file to .env format.

## Description

Converts an INI file to .env format via JSON intermediate conversion. All sections are flattened into key=value pairs.

## Signature

```powershell
ConvertTo-EnvFromIni
```

## Parameters

### -InputPath

The path to the INI file.

### -OutputPath

The path for the output .env file. If not specified, uses input path with .env extension.


## Outputs

System.String Returns the path to the output .env file.


## Examples

### Example 1

```powershell
ConvertTo-EnvFromIni -InputPath 'config.ini'
```

Converts config.ini to config.env.

## Aliases

This function has the following aliases:

- `ini-to-env` - Converts an INI file to .env format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/env.ps1
