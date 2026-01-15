# Copy-MinioFile

## Synopsis

Copies files using MinIO client.

## Description

Wrapper for mc cp command.

## Signature

```powershell
Copy-MinioFile
```

## Parameters

### -Source

Source path (local or MinIO).

### -Destination

Destination path (local or MinIO).


## Examples

### Example 1

`powershell
Copy-MinioFile -Source "local/file.txt" -Destination "myminio/bucket/file.txt"
``

### Example 2

`powershell
Copy-MinioFile -Source "myminio/bucket/file.txt" -Destination "local/file.txt"
``

## Aliases

This function has the following aliases:

- `mc-cp` - Copies files using MinIO client.


## Source

Defined in: ..\profile.d\minio.ps1
