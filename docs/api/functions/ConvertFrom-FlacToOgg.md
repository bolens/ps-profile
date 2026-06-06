# ConvertFrom-FlacToOgg

## Synopsis

Converts FLAC audio to OGG Vorbis format.

## Description

Converts a FLAC audio file to OGG Vorbis format using FFmpeg.

## Signature

```powershell
ConvertFrom-FlacToOgg
```

## Parameters

### -InputPath

Path to the input FLAC file.

### -OutputPath

Path for the output OGG file. If not specified, uses input path with .ogg extension.

### -Quality

Audio quality (0-10, default: 5). Higher values mean better quality but larger files.


## Examples

### Example 1

`powershell
ConvertFrom-FlacToOgg -InputPath "audio.flac" -OutputPath "audio.ogg" -Quality 7
``

## Aliases

This function has the following aliases:

- `flac-to-ogg` - Converts FLAC audio to OGG Vorbis format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/flac.ps1
