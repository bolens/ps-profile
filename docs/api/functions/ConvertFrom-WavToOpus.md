# ConvertFrom-WavToOpus

## Synopsis

Converts WAV audio to Opus format.

## Description

Converts a WAV audio file to Opus format using FFmpeg.

## Signature

```powershell
ConvertFrom-WavToOpus
```

## Parameters

### -InputPath

Path to the input WAV file.

### -OutputPath

Path for the output Opus file. If not specified, uses input path with .opus extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

`powershell
ConvertFrom-WavToOpus -InputPath "audio.wav" -OutputPath "audio.opus"
``

## Aliases

This function has the following aliases:

- `wav-to-opus` - Converts WAV audio to Opus format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/wav.ps1
