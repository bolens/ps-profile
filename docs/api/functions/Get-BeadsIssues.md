# Get-BeadsIssues

## Synopsis

Lists Beads issues with optional filters.

## Description

Lists issues matching the specified filters.

## Signature

```powershell
Get-BeadsIssues
```

## Parameters

### -Status

Filter by status (open, closed, in_progress).

### -Priority

Filter by priority level (0-4).

### -Assignee

Filter by assignee.

### -Labels

Filter by labels (comma-separated, AND logic).

### -LabelsAny

Filter by labels (comma-separated, OR logic).

### -Json

Return output in JSON format.


## Outputs

System.String. Output from bd list command.


## Examples

### Example 1

`powershell
Get-BeadsIssues -Status open
        Lists all open issues.
``

### Example 2

`powershell
Get-BeadsIssues -Priority 1 -Labels "urgent,backend"
        Lists P1 issues with both urgent and backend labels.
``

## Source

Defined in: ..\profile.d\beads.ps1
