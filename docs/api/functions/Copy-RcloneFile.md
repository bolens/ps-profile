# Copy-RcloneFile

## Synopsis

Copies files using rclone.

## Description

Wrapper for rclone copy command.

## Signature

```powershell
Copy-RcloneFile
```

## Parameters

### -Source

Source path (local or remote).

### -Destination

Destination path (local or remote).


## Examples

### Example 1

`powershell
Copy-RcloneFile -Source "remote:path" -Destination "local:path"
``

### Example 2

`powershell
Copy-RcloneFile -Source "local:path" -Destination "remote:path"
``

## Aliases

This function has the following aliases:

- `rcopy` - Copies files using rclone.


## Source

Defined in: ..\profile.d\26-rclone.ps1
