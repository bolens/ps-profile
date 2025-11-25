# Test-DocumentLatexEngineAvailable

## Synopsis

Tests whether a supported LaTeX engine is available.

## Description

Checks for pdflatex, xelatex, or luatex in the current environment and returns the first engine found so callers can select an appropriate --pdf-engine.

## Signature

```powershell
Test-DocumentLatexEngineAvailable
```

## Parameters

No parameters.

## Outputs

[string] - The name of the LaTeX engine if found; otherwise $null.


## Examples

No examples provided.

## Source

Defined in: ..\profile.d\02-files.ps1
