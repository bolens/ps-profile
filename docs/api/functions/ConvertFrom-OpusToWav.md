# ConvertFrom-OpusToWav

## Synopsis

Converts Opus audio to WAV format.

## Description

Converts an Opus audio file to WAV format using FFmpeg.

## Signature

```powershell
ConvertFrom-OpusToWav
```

## Parameters

### -InputPath

Path to the input Opus file.

### -OutputPath

Path for the output WAV file. If not specified, uses input path with .wav extension.


## Examples

### Example 1

```powershell
ConvertFrom-OpusToWav -InputPath "audio.opus" -OutputPath "audio.wav"
```

## Aliases

This function has the following aliases:

- `opus-to-wav` - Converts Opus audio to WAV format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/opus.ps1
