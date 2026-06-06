# Invoke-StarshipInitScript

## Synopsis

Executes Starship's initialization script and verifies it worked.

## Description

Runs `starship init powershell --print-full-init` to get the initialization script, writes it to a temp file, executes it, and verifies that a valid prompt function was created.

## Signature

```powershell
Invoke-StarshipInitScript
```

## Parameters

### -StarshipCommandPath

The path to the starship executable.


## Outputs

System.Management.Automation.FunctionInfo The created prompt function.


## Examples

No examples provided.

## Source

Defined in: ../profile.d/starship/StarshipInit.ps1
