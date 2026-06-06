# ConvertFrom-WavToMp3

## Synopsis

Converts WAV audio to MP3 format.

## Description

Converts a WAV audio file to MP3 format using FFmpeg.

## Signature

```powershell
ConvertFrom-WavToMp3
```

## Parameters

### -InputPath

Path to the input WAV file.

### -OutputPath

Path for the output MP3 file. If not specified, uses input path with .mp3 extension.

### -Bitrate

Audio bitrate in kbps (default: 192).


## Examples

### Example 1

`powershell
ConvertFrom-WavToMp3 -InputPath "audio.wav" -OutputPath "audio.mp3"
``

## Aliases

This function has the following aliases:

- `wav-to-mp3` - Converts WAV audio to MP3 format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/wav.ps1
