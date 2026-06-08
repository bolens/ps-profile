# ConvertFrom-OggToMp3

## Synopsis

Converts OGG Vorbis audio to MP3 format.

## Description

Converts an OGG Vorbis audio file to MP3 format using FFmpeg.

## Signature

```powershell
ConvertFrom-OggToMp3
```

## Parameters

### -InputPath

Path to the input OGG file.

### -OutputPath

Path for the output MP3 file. If not specified, uses input path with .mp3 extension.

### -Bitrate

Audio bitrate in kbps (default: 192).


## Examples

### Example 1

```powershell
ConvertFrom-OggToMp3 -InputPath "audio.ogg" -OutputPath "audio.mp3"
```

## Aliases

This function has the following aliases:

- `ogg-to-mp3` - Converts OGG Vorbis audio to MP3 format.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/ogg.ps1
