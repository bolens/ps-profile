# Convert-NumberBase

## Synopsis

Converts numbers between different bases.

## Description

Converts numbers between Binary, Octal, Decimal, and Hexadecimal bases.

## Signature

```powershell
Convert-NumberBase
```

## Parameters

### -Number

The number to convert (as a string).

### -FromBase

The base of the input number. Default is Decimal.

### -ToBase

The base to convert to. Default is Hexadecimal.


## Outputs

PSCustomObject Object containing Original, FromBase, ToBase, and Result properties.


## Examples

### Example 1

```powershell
Convert-NumberBase -Number "255" -FromBase Decimal -ToBase Hexadecimal
```

Converts 255 from decimal to hexadecimal (FF).

### Example 2

```powershell
Convert-NumberBase -Number "1010" -FromBase Binary -ToBase Decimal
```

Converts binary 1010 to decimal (10).

## Aliases

This function has the following aliases:

- `base-convert` - Converts numbers between different bases.


## Source

Defined in: ../profile.d/dev-tools-modules/data/number-base.ps1
