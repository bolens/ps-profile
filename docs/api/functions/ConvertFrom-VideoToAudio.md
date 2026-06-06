# ConvertFrom-VideoToAudio

## Synopsis

Extracts audio from video file.

## Description

Uses FFmpeg to extract audio track from a video file in the specified format.

## Signature

```powershell
ConvertFrom-VideoToAudio
```

## Parameters

### -InputPath

Path to the video file.

### -OutputPath

Path for the output audio file. If not specified, uses input path with format extension.

### -Format

Output audio format: mp3, aac, ogg, opus, flac, or wav (default: mp3).

### -Bitrate

Audio bitrate in kbps (default: 192). Used for mp3, aac, and opus formats.


## Examples

### Example 1

`powershell
ConvertFrom-VideoToAudio -InputPath "video.mp4" -OutputPath "audio.mp3" -Format mp3
``

## Aliases

This function has the following aliases:

- `video-to-audio` - Extracts audio from video file.


## Source

Defined in: ../profile.d/conversion-modules/media/audio/video.ps1
