# Clear-EventCollection

## Synopsis

Clears the collected wide events.

## Description

Clears the in-memory event collection. Useful for testing or periodic cleanup.

## Signature

```powershell
Clear-EventCollection
```

## Parameters

No parameters.

## Outputs

System.Int32. Number of events cleared.


## Examples

### Example 1

```powershell
Clear-EventCollection
```

Clears all collected events.

## Source

Defined in: ../profile.d/bootstrap/ErrorHandlingStandard.ps1
