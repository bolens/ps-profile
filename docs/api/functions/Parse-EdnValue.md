# Parse-EdnValue

## Synopsis

Initializes EDN format conversion utility functions.

## Description

Sets up internal conversion functions for EDN (Extensible Data Notation) format. EDN is a data format used in Clojure, similar to JSON but with more data types. Supports bidirectional conversions between EDN and JSON, and conversions to YAML. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Parse-EdnValue
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. EDN supports: keywords (:keyword), symbols, strings, numbers, booleans, nil, vectors [], maps {}, sets #{}, lists (), tagged literals. This implementation handles basic EDN structures (maps, vectors, lists, keywords, strings, numbers, booleans, nil).


## Source

Defined in: ../profile.d/conversion-modules/data/structured/edn.ps1
