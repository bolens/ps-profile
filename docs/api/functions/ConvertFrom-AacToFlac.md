# ConvertFrom-AacToFlac

## Synopsis

Converts AAC audio to FLAC format.

## Description

Converts an AAC audio file to FLAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-AacToFlac
```

## Parameters

### -InputPath

Path to the input AAC file.

### -OutputPath

Path for the output FLAC file. If not specified, uses input path with .flac extension.


## Examples

### Example 1

`powershell
ConvertFrom-AacToFlac -InputPath "audio.aac" -OutputPath "audio.flac"
``

## Aliases

This function has the following aliases:

- `aac-to-flac` - Converts AAC audio to FLAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/aac.ps1
