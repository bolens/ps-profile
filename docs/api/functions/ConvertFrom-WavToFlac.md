# ConvertFrom-WavToFlac

## Synopsis

Converts WAV audio to FLAC format.

## Description

Converts a WAV audio file to FLAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-WavToFlac
```

## Parameters

### -InputPath

Path to the input WAV file.

### -OutputPath

Path for the output FLAC file. If not specified, uses input path with .flac extension.


## Examples

### Example 1

`powershell
ConvertFrom-WavToFlac -InputPath "audio.wav" -OutputPath "audio.flac"
``

## Aliases

This function has the following aliases:

- `wav-to-flac` - Converts WAV audio to FLAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/wav.ps1
