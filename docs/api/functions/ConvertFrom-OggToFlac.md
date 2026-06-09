# ConvertFrom-OggToFlac

## Synopsis

Converts OGG Vorbis audio to FLAC format.

## Description

Converts an OGG Vorbis audio file to FLAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-OggToFlac
```

## Parameters

### -InputPath

Path to the input OGG file.

### -OutputPath

Path for the output FLAC file. If not specified, uses input path with .flac extension.


## Examples

### Example 1

```powershell
ConvertFrom-OggToFlac -InputPath "audio.ogg" -OutputPath "audio.flac"
```

## Aliases

This function has the following aliases:

- `ogg-to-flac` - Converts OGG Vorbis audio to FLAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/ogg.ps1
