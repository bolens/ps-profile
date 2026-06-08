# ConvertFrom-OpusToAac

## Synopsis

Converts Opus audio to AAC format.

## Description

Converts an Opus audio file to AAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-OpusToAac
```

## Parameters

### -InputPath

Path to the input Opus file.

### -OutputPath

Path for the output AAC file. If not specified, uses input path with .aac extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

```powershell
ConvertFrom-OpusToAac -InputPath "audio.opus" -OutputPath "audio.aac"
```

## Aliases

This function has the following aliases:

- `opus-to-aac` - Converts Opus audio to AAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/opus.ps1
