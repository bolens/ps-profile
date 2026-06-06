# ConvertFrom-WavToAac

## Synopsis

Converts WAV audio to AAC format.

## Description

Converts a WAV audio file to AAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-WavToAac
```

## Parameters

### -InputPath

Path to the input WAV file.

### -OutputPath

Path for the output AAC file. If not specified, uses input path with .aac extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

`powershell
ConvertFrom-WavToAac -InputPath "audio.wav" -OutputPath "audio.aac"
``

## Aliases

This function has the following aliases:

- `wav-to-aac` - Converts WAV audio to AAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/wav.ps1
