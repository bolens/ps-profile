# Initialize-Beads

## Synopsis

Initializes a Beads database in the current repository.

## Description

Initializes a new Beads issue tracker database in the current repository. This creates the .beads/ directory and sets up the database structure.

## Signature

```powershell
Initialize-Beads
```

## Parameters

### -Contributor

Initialize for contributor workflow (fork-based).

### -Team

Initialize for team workflow (branch-based).

### -Branch

Specify a branch name for protected branch workflows.

### -Quiet

Run initialization non-interactively (for agents).


## Outputs

System.String. Output from bd init command.


## Examples

### Example 1

`powershell
Initialize-Beads
        Initializes Beads in the current repository.
``

### Example 2

`powershell
Initialize-Beads -Contributor
        Initializes Beads for contributor workflow.
``

## Source

Defined in: ..\profile.d\beads.ps1
