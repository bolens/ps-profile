# Invoke-Beads

## Synopsis

Executes Beads (bd) commands.

## Description

Wrapper function for Beads CLI (bd) that executes commands for managing issues, dependencies, and ready work. Beads is a lightweight memory system for coding agents using a graph-based issue tracker.

## Signature

```powershell
Invoke-Beads
```

## Parameters

### -Arguments

Arguments to pass to bd command. Can be used multiple times or as an array.


## Outputs

System.String. Output from bd execution.


## Examples

### Example 1

`powershell
Invoke-Beads init
        Initializes a new Beads database in the current repository.
``

### Example 2

`powershell
Invoke-Beads ready
        Shows issues that are ready to work on (no blockers).
``

### Example 3

`powershell
Invoke-Beads create "Fix bug" -p 1
        Creates a new issue with title "Fix bug" and priority 1.
``

## Aliases

This function has the following aliases:

- `bd` - Executes Beads (bd) commands.


## Source

Defined in: ..\profile.d\beads.ps1
