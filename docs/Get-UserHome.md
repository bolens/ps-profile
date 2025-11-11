# Get-UserHome

## Synopsis

Gets the user's home directory path.

## Description

Returns the user's home directory path in a cross-platform compatible way. Uses $env:HOME on Unix systems and $env:USERPROFILE on Windows.

## Signature

```powershell
Get-UserHome
```

## Parameters

No parameters.

## Outputs

System.String. The path to the user's home directory. .EXAMPLE $homeDir = Get-UserHome $configPath = Join-Path $homeDir '.config' 'myapp' .EXAMPLE # Use in cross-platform path construction $downloads = Join-Path (Get-UserHome) 'Downloads' if (Test-Path $downloads) { Set-Location $downloads }


## Examples

### Example 1

`powershell
$homeDir = Get-UserHome
        $configPath = Join-Path $homeDir '.config' 'myapp'
``

### Example 2

`powershell
# Use in cross-platform path construction
        $downloads = Join-Path (Get-UserHome) 'Downloads'
        if (Test-Path $downloads) {
            Set-Location $downloads
        }
``

## Notes

This function provides a consistent way to get the user's home directory across Windows, Linux, and macOS. Prefer this over direct use of $env:USERPROFILE or $env:HOME for better cross-platform compatibility.


## Source

Defined in: profile.d\00-bootstrap.ps1
