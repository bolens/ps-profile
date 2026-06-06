# ConvertFrom-BrailleToAscii

## Synopsis

Converts Braille encoding to ASCII text.

## Description

Decodes Unicode Braille patterns back to ASCII text. Supports standard 6-dot Braille patterns.

## Signature

```powershell
ConvertFrom-BrailleToAscii
```

## Parameters

### -InputObject

The Braille encoded string (Unicode characters).


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

`powershell
"⠓⠑⠇⠇⠕" | ConvertFrom-BrailleToAscii
    
    Converts Braille to text.
``

## Aliases

This function has the following aliases:

- `braille-to-ascii` - Converts Braille encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/braille.ps1
