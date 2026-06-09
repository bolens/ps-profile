# ConvertFrom-AacToOpus

## Synopsis

Converts AAC audio to Opus format.

## Description

Converts an AAC audio file to Opus format using FFmpeg.

## Signature

```powershell
ConvertFrom-AacToOpus
```

## Parameters

### -InputPath

Path to the input AAC file.

### -OutputPath

Path for the output Opus file. If not specified, uses input path with .opus extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

```powershell
ConvertFrom-AacToOpus -InputPath "audio.aac" -OutputPath "audio.opus"
```

## Aliases

This function has the following aliases:

- `aac-to-opus` - Converts AAC audio to Opus format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/aac.ps1
