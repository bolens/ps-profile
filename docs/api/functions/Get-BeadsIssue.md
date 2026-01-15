# Get-BeadsIssue

## Synopsis

Gets details of a specific Beads issue.

## Description

Retrieves full details of an issue by its ID.

## Signature

```powershell
Get-BeadsIssue
```

## Parameters

### -IssueId

The issue ID (e.g., bd-a1b2).

### -Json

Return output in JSON format.


## Outputs

System.String. Output from bd show command.


## Examples

### Example 1

`powershell
Get-BeadsIssue -IssueId bd-a1b2
        Gets details for issue bd-a1b2.
``

## Source

Defined in: ..\profile.d\beads.ps1
