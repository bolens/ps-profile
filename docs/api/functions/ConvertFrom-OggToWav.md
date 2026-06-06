# ConvertFrom-OggToWav

## Synopsis

Converts OGG Vorbis audio to WAV format.

## Description

Converts an OGG Vorbis audio file to WAV format using FFmpeg.

## Signature

```powershell
ConvertFrom-OggToWav
```

## Parameters

### -InputPath

Path to the input OGG file.

### -OutputPath

Path for the output WAV file. If not specified, uses input path with .wav extension.


## Examples

### Example 1

`powershell
ConvertFrom-OggToWav -InputPath "audio.ogg" -OutputPath "audio.wav"
``

## Aliases

This function has the following aliases:

- `ogg-to-wav` - Converts OGG Vorbis audio to WAV format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/ogg.ps1
