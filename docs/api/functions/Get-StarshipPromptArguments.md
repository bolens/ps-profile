# Get-StarshipPromptArguments

## Synopsis

Builds arguments array for starship prompt command.

## Description

Constructs the command-line arguments that Starship needs to render the prompt, including terminal width, job count, command status, and execution duration.

## Signature

```powershell
Get-StarshipPromptArguments
```

## Parameters

### -LastCommandSucceeded

Whether the last command succeeded.

### -LastExitCode

The exit code of the last command.


## Outputs

System.String[]


## Examples

### Example 1

```powershell
Get-StarshipPromptArguments -LastCommandSucceeded -LastExitCode 1
```

## Source

Defined in: ../profile.d/starship/StarshipHelpers.ps1
