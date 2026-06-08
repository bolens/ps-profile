# Invoke-GumSpin

## Synopsis

Shows a spinner while executing a script block using gum.

## Description

Displays a spinning indicator with a title while executing the provided script block.

## Signature

```powershell
Invoke-GumSpin
```

## Parameters

### -Title

Spinner label shown while the script block runs.

### -Script

Script block executed under the spinner.


## Examples

### Example 1

```powershell
Invoke-GumSpin -Title 'Fetching data...' -Script { Invoke-RestMethod https://example.com }
```

## Aliases

This function has the following aliases:

- `spin` - Shows a spinner while executing a script block using gum.


## Source

Defined in: ../profile.d/gum.ps1
