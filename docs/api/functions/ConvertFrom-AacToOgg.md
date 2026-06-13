# ConvertFrom-AacToOgg

## Synopsis

Converts AAC audio to OGG Vorbis format.

## Description

Converts an AAC audio file to OGG Vorbis format using FFmpeg.

## Signature

```powershell
ConvertFrom-AacToOgg
```

## Parameters

### -InputPath

Path to the input AAC file.

### -OutputPath

Path for the output OGG file. If not specified, uses input path with .ogg extension.

### -Quality

Audio quality (0-10, default: 5). Higher values mean better quality but larger files.


## Examples

### Example 1

```powershell
ConvertFrom-AacToOgg -InputPath "audio.aac" -OutputPath "audio.ogg"
```

## Aliases

This function has the following aliases:

- `aac-to-ogg` - Converts AAC audio to OGG Vorbis format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/aac.ps1
