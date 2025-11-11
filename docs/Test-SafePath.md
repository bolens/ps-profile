# Test-SafePath

## Synopsis

Validates that a path is safe and within a base directory.

## Description

Checks if a resolved path is within a specified base directory to prevent path traversal attacks. Useful for validating user input before file operations.

## Signature

```powershell
Test-SafePath
```

## Parameters

### -Path

The path to validate.

### -BasePath

The base directory that the path must be within.


## Outputs

System.Boolean. Returns $true if path is safe, $false otherwise. .EXAMPLE if (Test-SafePath -Path $userPath -BasePath $homeDir) { # Safe to use the path }


## Examples

### Example 1

`powershell
if (Test-SafePath -Path $userPath -BasePath $homeDir) {
        # Safe to use the path
    }
``

## Source

Defined in: profile.d\05-utilities.ps1
