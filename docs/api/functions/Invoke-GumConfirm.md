# Invoke-GumConfirm

## Synopsis

Shows a confirmation prompt using gum.

## Description

Displays an interactive confirmation dialog using gum. Returns true if confirmed, false otherwise.

## Signature

```powershell
Invoke-GumConfirm
```

## Parameters

### -Prompt

Confirmation message shown to the user.


## Outputs

System.Boolean


## Examples

### Example 1

```powershell
if (Invoke-GumConfirm -Prompt 'Delete file?') { Remove-Item ./temp.txt }
```

## Aliases

This function has the following aliases:

- `confirm` - Shows a confirmation prompt using gum.


## Source

Defined in: ../profile.d/gum.ps1
