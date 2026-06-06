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

The project supports MiKTeX on Windows and TeX Live / MacTeX on Linux/macOS.


## Source

Defined in: ../profile.d/files/LaTeXDetection.ps1
