# ConvertFrom-Hdf5ToJson

## Synopsis

Converts HDF5 file to JSON format.

## Description

Converts an HDF5 (Hierarchical Data Format version 5) file back to JSON format. Requires Python with h5py package to be installed.

## Signature

```powershell
ConvertFrom-Hdf5ToJson
```

## Parameters

### -InputPath

The path to the HDF5 file.

### -OutputPath

The path for the output JSON file. If not specified, uses input path with .json extension.


## Examples

### Example 1

```powershell
ConvertFrom-Hdf5ToJson -InputPath ./input.file
```

## Aliases

This function has the following aliases:

- `h5-to-json` - Converts HDF5 file to JSON format.
- `hdf5-to-json` - Converts HDF5 file to JSON format.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-hdf5.ps1
