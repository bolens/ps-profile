# ConvertFrom-FlacToAac

## Synopsis

Converts FLAC audio to AAC format.

## Description

Converts a FLAC audio file to AAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-FlacToAac
```

## Parameters

### -InputPath

Path to the input FLAC file.

### -OutputPath

Path for the output AAC file. If not specified, uses input path with .aac extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

`powershell
ConvertFrom-FlacToAac -InputPath "audio.flac" -OutputPath "audio.aac" -Bitrate 192
``

## Aliases

This function has the following aliases:

- `flac-to-aac` - Converts FLAC audio to AAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/flac.ps1
