# Restore-ContainerVolumes

## Synopsis

Restores container volumes from a backup archive.

## Description

Restores volumes from a backup tar archive. Works with both Docker and Podman.

## Signature

```powershell
Restore-ContainerVolumes
```

## Parameters

### -BackupPath

Path to the backup archive file.

### -Volume

Volume name to restore to. If not specified, creates a new volume.

### -CreateVolume

Create a new volume if it doesn't exist.


## Outputs

System.String. Name of the restored volume.


## Examples

### Example 1

`powershell
Restore-ContainerVolumes -BackupPath "volume-backup.tar.gz"
        
        Restores volumes from backup archive.
``

### Example 2

`powershell
Restore-ContainerVolumes -BackupPath "backup.tar.gz" -Volume "my-volume" -CreateVolume
        
        Restores to my-volume, creating it if needed.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
