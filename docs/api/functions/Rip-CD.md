# Rip-CD

## Synopsis

Rips audio from a CD.

## Description

Rips audio tracks from a CD using cyanrip. Supports various output formats and quality settings.

## Signature

```powershell
Rip-CD
```

## Parameters

### -OutputPath

Directory where ripped audio files will be saved.

### -Format

Output format: flac, mp3, wav, opus. Defaults to flac.

### -Quality

Quality setting (for lossy formats). Defaults to 0 (highest quality).


## Outputs

System.String. Path to the output directory.


## Examples

### Example 1

`powershell
Rip-CD -OutputPath "C:\Music\Album"
        
        Rips CD to FLAC format in the specified directory.
``

### Example 2

`powershell
Rip-CD -OutputPath "C:\Music\Album" -Format "mp3" -Quality 0
        
        Rips CD to MP3 format with highest quality.
``

## Source

Defined in: ..\profile.d\media-tools.ps1
