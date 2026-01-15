# New-BeadsIssue

## Synopsis

Creates a new Beads issue.

## Description

Creates a new issue in the Beads tracker with the specified title and optional metadata.

## Signature

```powershell
New-BeadsIssue
```

## Parameters

### -Title

Title of the issue.

### -Description

Detailed description of the issue.

### -Priority

Priority level (0-4, where 0 is highest, default is 2).

### -Type

Issue type: bug, feature, task, epic, or chore (default: task).

### -Assignee

Assign issue to a user.

### -Labels

Comma-separated list of labels.

### -Json

Return output in JSON format.


## Outputs

System.String. Output from bd create command.


## Examples

### Example 1

`powershell
New-BeadsIssue -Title "Fix bug" -Priority 1 -Type bug
        Creates a P1 bug issue.
``

### Example 2

`powershell
New-BeadsIssue -Title "Add feature" -Description "Detailed description" -Type feature
        Creates a feature issue with description.
``

## Source

Defined in: ..\profile.d\beads.ps1
