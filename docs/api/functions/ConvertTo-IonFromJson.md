# ConvertTo-IonFromJson

## Synopsis

Converts JSON file to Ion format.

## Description

Converts a JSON file to Ion format (text or binary). Ion is a richly-typed, self-describing, hierarchical data serialization format. Requires Python and the ion-python package to be installed.

## Signature

```powershell
ConvertTo-IonFromJson [String]$InputPath, [String]$OutputPath, [SwitchParameter]$Binary
```

## Parameters

### -InputPath

**Type:** [String]

The path to the JSON file.

### -OutputPath

**Type:** [String]

The path for the output Ion file. If not specified, uses input path with .ion extension.

### -Binary

**Type:** [SwitchParameter]

If specified, creates binary Ion format (.10n) instead of text format (.ion).


## Outputs

System.String Returns the path to the output Ion file.


## Examples

### Example 1

```powershell
ConvertTo-IonFromJson -InputPath 'data.json'
```

Converts data.json to data.ion (text format).

### Example 2

```powershell
ConvertTo-IonFromJson -InputPath 'data.json' -Binary
```

Converts data.json to data.10n (binary format).

## Aliases

This function has the following aliases:

- `json-to-ion` - Converts JSON file to Ion format.


## Source

Defined in: ../profile.d/conversion-modules/data/structured/ion.ps1
