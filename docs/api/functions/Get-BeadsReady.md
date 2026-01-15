# Get-BeadsReady

## Synopsis

Gets issues that are ready to work on (no blockers).

## Description

Returns a list of issues that have no open blockers and are ready to be worked on.

## Signature

```powershell
Get-BeadsReady
```

## Parameters

### -Limit

Maximum number of issues to return.

### -Priority

Filter by priority level (0-4, where 0 is highest).

### -Assignee

Filter by assignee.

### -Sort

Sort order: priority, oldest, or hybrid (default).

### -Json

Return output in JSON format.


## Outputs

System.String. Output from bd ready command.


## Examples

### Example 1

`powershell
Get-BeadsReady
        Gets all ready issues.
``

### Example 2

`powershell
Get-BeadsReady -Limit 10 -Priority 1
        Gets top 10 P1 ready issues.
``

## Source

Defined in: ..\profile.d\beads.ps1
