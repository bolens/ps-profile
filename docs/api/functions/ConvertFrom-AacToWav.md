# ConvertFrom-AacToWav

## Synopsis

Converts AAC audio to WAV format.

## Description

Converts an AAC audio file to WAV format using FFmpeg.

## Signature

```powershell
ConvertFrom-AacToWav
```

## Parameters

### -InputPath

Path to the input AAC file.

### -OutputPath

Path for the output WAV file. If not specified, uses input path with .wav extension.


## Examples

### Example 1

```powershell
ConvertFrom-AacToWav -InputPath "audio.aac" -OutputPath "audio.wav"
```

## Aliases

This function has the following aliases:

- `aac-to-wav` - Converts AAC audio to WAV format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/aac.ps1
