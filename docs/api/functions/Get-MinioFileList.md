# Get-MinioFileList

## Synopsis

Lists files in MinIO storage.

## Description

Wrapper for mc ls command.

## Signature

```powershell
Get-MinioFileList
```

## Parameters

### -Path

Path to list in MinIO.


## Examples

### Example 1

`powershell
Get-MinioFileList -Path "myminio/bucket/path"
``

### Example 2

`powershell
Get-MinioFileList -Path "myminio/bucket/"
``

## Aliases

This function has the following aliases:

- `mc-ls` - Lists files in MinIO storage.


## Source

Defined in: ..\profile.d\minio.ps1
