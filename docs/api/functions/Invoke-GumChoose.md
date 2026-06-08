# Invoke-GumChoose

## Synopsis

Shows an interactive selection menu using gum.

## Description

Displays a list of options for the user to choose from using gum's interactive chooser.

## Signature

```powershell
Invoke-GumChoose
```

## Parameters

### -Options

Choices presented to the user.

### -Prompt

Header text shown above the chooser.


## Examples

### Example 1

```powershell
Invoke-GumChoose -Options 'dev', 'staging', 'prod' -Prompt 'Environment'
```

## Aliases

This function has the following aliases:

- `choose` - Shows an interactive selection menu using gum.


## Source

Defined in: ../profile.d/gum.ps1
