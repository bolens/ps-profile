# ConvertFrom-OpusToMp3

## Synopsis

Converts Opus audio to MP3 format.

## Description

Converts an Opus audio file to MP3 format using FFmpeg.

## Signature

```powershell
ConvertFrom-OpusToMp3
```

## Parameters

### -InputPath

Path to the input Opus file.

### -OutputPath

Path for the output MP3 file. If not specified, uses input path with .mp3 extension.

### -Bitrate

Audio bitrate in kbps (default: 192).


## Examples

### Example 1

```powershell
ConvertFrom-OpusToMp3 -InputPath "audio.opus" -OutputPath "audio.mp3"
```

## Aliases

This function has the following aliases:

- `opus-to-mp3` - Converts Opus audio to MP3 format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/opus.ps1
