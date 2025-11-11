# Invoke-GitCommand

## Synopsis

Invokes a Git subcommand with repository safety guards.

## Description

Provides a central wrapper that optionally validates repository context and commit availability before forwarding execution to `git`. Prevents noisy failures when the profile runs outside a repo or against a freshly initialized repository.

## Signature

```powershell
Invoke-GitCommand
```

## Parameters

### -Subcommand

The git subcommand to execute (for example, 'status' or 'pull').

### -Arguments

Additional arguments to pass to git. Defaults to an empty array.

### -CommandName

Friendly label for verbose/log messages. Defaults to "git <Subcommand>".

### -SkipRepositoryCheck

Skips the repository existence check when specified.

### -RequiresCommit

Requires that the repository contains commits before executing.


## Examples

### Example 1

`powershell
Invoke-GitCommand -Subcommand 'status' -Arguments @('--short')
    Runs `git status --short` if the current directory is a Git repository.
``

## Source

Defined in: profile.d\11-git.ps1
