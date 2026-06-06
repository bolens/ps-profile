# Update-PerformanceInsightsPrompt

## Synopsis

Wraps the current prompt function with performance timing.

## Description

Wraps the active prompt function (Starship, Oh-My-Posh, or default) with performance timing functionality. This function can be called multiple times to re-wrap the prompt after prompt frameworks initialize, ensuring performance insights work correctly with any prompt system.

## Signature

```powershell
Update-PerformanceInsightsPrompt
```

## Parameters

No parameters.

## Examples

### Example 1

`powershell
Update-PerformanceInsightsPrompt
        
        Wraps the current prompt function with performance timing.
``

## Notes

This function is called automatically when the performance insights fragment loads, and should be called again after Starship or other prompt frameworks initialize to ensure the wrapper captures the final prompt function. .EXAMPLE Update-PerformanceInsightsPrompt Wraps the current prompt function with performance timing.


## Source

Defined in: ../profile.d/diagnostics-modules/monitoring/diagnostics-performance.ps1
