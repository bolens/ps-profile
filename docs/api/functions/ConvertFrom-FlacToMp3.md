# ConvertFrom-FlacToMp3

## Synopsis

Converts FLAC audio to MP3 format.

## Description

Converts a FLAC audio file to MP3 format using FFmpeg.

## Signature

```powershell
ConvertFrom-FlacToMp3
```

## Parameters

### -InputPath

Path to the input FLAC file.

### -OutputPath

Path for the output MP3 file. If not specified, uses input path with .mp3 extension.

### -Bitrate

Audio bitrate in kbps (default: 192).


## Examples

### Example 1

`powershell
ConvertFrom-FlacToMp3 -InputPath "audio.flac" -OutputPath "audio.mp3" -Bitrate 256
``

## Aliases

This function has the following aliases:

- `flac-to-mp3` - Converts FLAC audio to MP3 format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/flac.ps1
