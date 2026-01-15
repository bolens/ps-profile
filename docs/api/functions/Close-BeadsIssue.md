# Close-BeadsIssue

## Synopsis

Closes a Beads issue.

## Description

Closes one or more issues with an optional reason.

## Signature

```powershell
Close-BeadsIssue
```

## Parameters

### -IssueId

One or more issue IDs to close.

### -Reason

Reason for closing the issue.

### -Json

Return output in JSON format.


## Outputs

System.String. Output from bd close command.


## Examples

### Example 1

`powershell
Close-BeadsIssue -IssueId bd-a1b2 -Reason "Completed"
        Closes issue bd-a1b2 with reason "Completed".
``

### Example 2

`powershell
Close-BeadsIssue -IssueId bd-a1b2,bd-f14c -Reason "Fixed"
        Closes multiple issues.
``

## Source

Defined in: ..\profile.d\beads.ps1
