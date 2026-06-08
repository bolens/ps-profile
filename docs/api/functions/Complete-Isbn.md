# Complete-Isbn

## Synopsis

Completes a partial ISBN by calculating the missing check digit.

## Description

Accepts nine ISBN-10 digits or twelve ISBN-13 digits and appends the correct check digit.

## Signature

```powershell
Complete-Isbn
```

## Parameters

### -Isbn

Partial ISBN value.


## Outputs

PSCustomObject


## Examples

### Example 1

```powershell
Complete-Isbn -Isbn '978030640615'
```

## Aliases

This function has the following aliases:

- `isbn-complete` - Completes a partial ISBN by calculating the missing check digit.


## Source

Defined in: ../profile.d/utilities-modules/data/utilities-isbn-extended.ps1
