# Backup-ContainerVolumes

## Synopsis

Backs up container volumes to a tar archive.

## Description

Creates a backup of container volumes. Works with both Docker and Podman.

## Signature

```powershell
Backup-ContainerVolumes
```

## Parameters

### -Volume

Volume name. If not specified, backs up all volumes.

### -OutputPath

Path to save backup file. Defaults to volume-backup-{timestamp}.tar.gz.

### -Compress

Compress the backup archive (gzip).


## Outputs

System.String. Path to the backup file.


## Examples

### Example 1

`powershell
Backup-ContainerVolumes -Volume "my-volume"
        
        Backs up my-volume to a tar file.
``

### Example 2

`powershell
Backup-ContainerVolumes -Compress
        
        Backs up all volumes to a compressed archive.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
