# ConvertTo-XmlFromYaml

## Synopsis

Initializes text format gap conversion utility functions.

## Description

Sets up internal conversion functions for direct text format conversions that fill gaps in the conversion matrix: XML↔YAML, JSONL↔CSV, JSONL↔YAML. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
ConvertTo-XmlFromYaml
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires yq for XML↔YAML conversions.


## Aliases

This function has the following aliases:

- `yaml-to-xml` - Initializes text format gap conversion utility functions.


## Source

Defined in: ../profile.d/conversion-modules/data/core/text-gaps.ps1
