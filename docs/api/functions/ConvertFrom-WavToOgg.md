# ConvertFrom-WavToOgg

## Synopsis

Converts WAV audio to OGG Vorbis format.

## Description

Converts a WAV audio file to OGG Vorbis format using FFmpeg.

## Signature

```powershell
ConvertFrom-WavToOgg
```

## Parameters

### -InputPath

Path to the input WAV file.

### -OutputPath

Path for the output OGG file. If not specified, uses input path with .ogg extension.

### -Quality

Audio quality (0-10, default: 5). Higher values mean better quality but larger files.


## Examples

### Example 1

```powershell
ConvertFrom-WavToOgg -InputPath "audio.wav" -OutputPath "audio.ogg"
```

## Aliases

This function has the following aliases:

- `wav-to-ogg` - Converts WAV audio to OGG Vorbis format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/wav.ps1
