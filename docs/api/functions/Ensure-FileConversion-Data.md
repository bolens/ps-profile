# Ensure-FileConversion-Data

## Synopsis

Initializes data format conversion utility functions on first use.

## Description

Sets up all data format conversion utility functions when any of them is called for the first time. This lazy loading approach improves profile startup performance. Loads conversion modules from the conversion-modules subdirectory.

## Signature

```powershell
Ensure-FileConversion-Data
```

## Parameters

No parameters.

## Examples

No examples provided.

## Source

Defined in: ..\profile.d\files.ps1
