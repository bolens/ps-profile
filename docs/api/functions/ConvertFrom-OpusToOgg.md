# ConvertFrom-OpusToOgg

## Synopsis

Converts Opus audio to OGG Vorbis format.

## Description

Converts an Opus audio file to OGG Vorbis format using FFmpeg.

## Signature

```powershell
ConvertFrom-OpusToOgg
```

## Parameters

### -InputPath

Path to the input Opus file.

### -OutputPath

Path for the output OGG file. If not specified, uses input path with .ogg extension.

### -Quality

Audio quality (0-10, default: 5). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-OpusToOgg -InputPath "audio.opus" -OutputPath "audio.ogg"
``

## Aliases

This function has the following aliases:

- `opus-to-ogg` - Converts Opus audio to OGG Vorbis format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/opus.ps1
