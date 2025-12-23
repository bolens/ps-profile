# Get-RcloneFileList

## Synopsis

Lists files using rclone.

## Description

Wrapper for rclone ls command.

## Signature

```powershell
Get-RcloneFileList
```

## Parameters

### -Path

Path to list (local or remote).


## Examples

### Example 1

`powershell
Get-RcloneFileList -Path "remote:path"
``

### Example 2

`powershell
Get-RcloneFileList -Path "local:path"
``

## Aliases

This function has the following aliases:

- `rls` - Lists files using rclone.


## Source

Defined in: ..\profile.d\26-rclone.ps1
