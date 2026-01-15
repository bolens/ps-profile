# Extract-Audio

## Synopsis

Extracts audio from a video file.

## Description

Extracts audio track from a video file and saves it as an audio file. Supports various audio formats (mp3, flac, wav, etc.).

## Signature

```powershell
Extract-Audio
```

## Parameters

### -InputPath

Path to the input video file.

### -OutputPath

Path to the output audio file.

### -AudioCodec

Audio codec to use (mp3, flac, wav, aac). Defaults to mp3.

### -Bitrate

Audio bitrate (for lossy codecs). Defaults to 192k for mp3.


## Outputs

System.String. Path to the extracted audio file.


## Examples

### Example 1

`powershell
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3"
        
        Extracts audio from video.mp4 and saves as audio.mp3.
``

### Example 2

`powershell
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.flac" -AudioCodec "flac"
        
        Extracts audio as FLAC format.
``

## Source

Defined in: ..\profile.d\media-tools.ps1
