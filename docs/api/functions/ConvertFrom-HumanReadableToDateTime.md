# ConvertFrom-HumanReadableToDateTime

## Synopsis

Converts a human-readable date string to a DateTime object.

## Description

Converts natural language date expressions to DateTime objects. Supports expressions like "tomorrow", "next week", "2 days ago", "in 3 hours", etc.

## Signature

```powershell
ConvertFrom-HumanReadableToDateTime
```

## Parameters

### -HumanReadableString

The human-readable date string to convert.


## Outputs

System.DateTime Returns a DateTime object representing the parsed date.


## Examples

### Example 1

`powershell
"tomorrow" | ConvertFrom-HumanReadableToDateTime
    
    Converts "tomorrow" to a DateTime object.
``

### Example 2

`powershell
"2 days ago" | ConvertFrom-HumanReadableToDateTime
    
    Converts "2 days ago" to a DateTime object.
``

### Example 3

`powershell
"next Monday" | ConvertFrom-HumanReadableToDateTime
    
    Converts "next Monday" to a DateTime object.
``

## Aliases

This function has the following aliases:

- `human-to-datetime` - Converts a human-readable date string to a DateTime object.


## Source

Defined in: ../profile.d/conversion-modules/data/time/human-readable.ps1
