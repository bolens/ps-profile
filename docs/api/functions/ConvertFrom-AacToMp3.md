# ConvertFrom-AacToMp3

## Synopsis

Converts AAC audio to MP3 format.

## Description

Converts an AAC audio file to MP3 format using FFmpeg.

## Signature

```powershell
ConvertFrom-AacToMp3
```

## Parameters

### -InputPath

Path to the input AAC file.

### -OutputPath

Path for the output MP3 file. If not specified, uses input path with .mp3 extension.

### -Bitrate

Audio bitrate in kbps (default: 192).


## Examples

### Example 1

```powershell
ConvertFrom-AacToMp3 -InputPath "audio.aac" -OutputPath "audio.mp3"
```

## Aliases

This function has the following aliases:

- `aac-to-mp3` - Converts AAC audio to MP3 format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/aac.ps1
