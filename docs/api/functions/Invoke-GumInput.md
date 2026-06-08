# Invoke-GumInput

## Synopsis

Shows an input prompt using gum.

## Description

Displays an interactive input field using gum with optional placeholder text.

## Signature

```powershell
Invoke-GumInput
```

## Parameters

### -Prompt

Input prompt label.

### -Placeholder

Placeholder text shown in the input field.


## Examples

### Example 1

`powershell
Invoke-GumInput -Prompt 'Branch:' -Placeholder 'feature/my-change'
``

## Aliases

This function has the following aliases:

- `input` - Shows an input prompt using gum.


## Source

Defined in: ../profile.d/gum.ps1
