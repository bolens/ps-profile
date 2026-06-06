# ConvertFrom-FlacToWav

## Synopsis

Converts FLAC audio to WAV format.

## Description

Converts a FLAC audio file to WAV format using FFmpeg.

## Signature

```powershell
ConvertFrom-FlacToWav
```

## Parameters

### -InputPath

Path to the input FLAC file.

### -OutputPath

Path for the output WAV file. If not specified, uses input path with .wav extension.


## Examples

### Example 1

`powershell
ConvertFrom-FlacToWav -InputPath "audio.flac" -OutputPath "audio.wav"
``

## Aliases

This function has the following aliases:

- `flac-to-wav` - Converts FLAC audio to WAV format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/flac.ps1
