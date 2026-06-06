# ConvertFrom-FlacToOpus

## Synopsis

Converts FLAC audio to Opus format.

## Description

Converts a FLAC audio file to Opus format using FFmpeg.

## Signature

```powershell
ConvertFrom-FlacToOpus
```

## Parameters

### -InputPath

Path to the input FLAC file.

### -OutputPath

Path for the output Opus file. If not specified, uses input path with .opus extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

`powershell
ConvertFrom-FlacToOpus -InputPath "audio.flac" -OutputPath "audio.opus" -Bitrate 192
``

## Aliases

This function has the following aliases:

- `flac-to-opus` - Converts FLAC audio to Opus format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/flac.ps1
