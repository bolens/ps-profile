# ConvertFrom-OpusToFlac

## Synopsis

Converts Opus audio to FLAC format.

## Description

Converts an Opus audio file to FLAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-OpusToFlac
```

## Parameters

### -InputPath

Path to the input Opus file.

### -OutputPath

Path for the output FLAC file. If not specified, uses input path with .flac extension.


## Examples

### Example 1

```powershell
ConvertFrom-OpusToFlac -InputPath "audio.opus" -OutputPath "audio.flac"
```

## Aliases

This function has the following aliases:

- `opus-to-flac` - Converts Opus audio to FLAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/opus.ps1
