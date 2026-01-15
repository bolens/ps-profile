# Update-BeadsIssue

## Synopsis

Updates a Beads issue.

## Description

Updates an existing issue with new status, priority, assignee, or other fields.

## Signature

```powershell
Update-BeadsIssue
```

## Parameters

### -IssueId

The issue ID to update (e.g., bd-a1b2).

### -Status

New status (open, closed, in_progress).

### -Priority

New priority level (0-4).

### -Assignee

New assignee.

### -Json

Return output in JSON format.


## Outputs

System.String. Output from bd update command.


## Examples

### Example 1

`powershell
Update-BeadsIssue -IssueId bd-a1b2 -Status in_progress
        Updates issue status to in_progress.
``

### Example 2

`powershell
Update-BeadsIssue -IssueId bd-a1b2 -Priority 0
        Updates issue priority to P0.
``

## Source

Defined in: ..\profile.d\beads.ps1
