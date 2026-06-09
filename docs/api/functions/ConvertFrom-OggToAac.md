# ConvertFrom-OggToAac

## Synopsis

Converts OGG Vorbis audio to AAC format.

## Description

Converts an OGG Vorbis audio file to AAC format using FFmpeg.

## Signature

```powershell
ConvertFrom-OggToAac
```

## Parameters

### -InputPath

Path to the input OGG file.

### -OutputPath

Path for the output AAC file. If not specified, uses input path with .aac extension.

### -Bitrate

Audio bitrate in kbps (default: 128).


## Examples

### Example 1

```powershell
ConvertFrom-OggToAac -InputPath "audio.ogg" -OutputPath "audio.aac"
```

## Aliases

This function has the following aliases:

- `ogg-to-aac` - Converts OGG Vorbis audio to AAC format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/ogg.ps1
