# Ensure-DocumentLatexEngine

## Synopsis

Ensures a LaTeX engine is available for PDF conversions.

## Description

Invokes Test-DocumentLatexEngineAvailable and, when no engine is present, raises Write-MissingToolWarning with MiKTeX installation guidance before throwing.

## Signature

```powershell
Ensure-DocumentLatexEngine
```

## Parameters

No parameters.

## Outputs

[string] - The detected LaTeX engine name.


## Examples

No examples provided.

## Notes

The project assumes Scoop is installed; MiKTeX can be installed via `scoop install miktex`.


## Source

Defined in: ..\profile.d\02-files.ps1
