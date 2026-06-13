# ConvertFrom-OggToOpus

## Synopsis

Converts OGG Vorbis audio to Opus format.

## Description

Converts an OGG Vorbis audio file to Opus format using FFmpeg.

## Signature

```powershell
ConvertFrom-OggToOpus
```

## Parameters

### -InputPath

Path to the input OGG file.

### -OutputPath

Path for the output Opus file. If not specified, uses input path with .opus extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

```powershell
ConvertFrom-OggToOpus -InputPath "audio.ogg" -OutputPath "audio.opus"
```

## Aliases

This function has the following aliases:

- `ogg-to-opus` - Converts OGG Vorbis audio to Opus format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/ogg.ps1
