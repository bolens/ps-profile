# Convert-Video

## Synopsis

Converts video files using ffmpeg or handbrake.

## Description

Converts video files to different formats and codecs. Supports both ffmpeg (flexible) and handbrake (preset-based) conversion.

## Signature

```powershell
Convert-Video
```

## Parameters

### -InputPath

Path to the input video file.

### -OutputPath

Path to the output video file.

### -Codec

Video codec to use (e.g., h264, hevc, vp9). Defaults to h264.

### -Preset

Handbrake preset to use (if using handbrake). Ignored if using ffmpeg.

### -UseHandbrake

Use Handbrake instead of ffmpeg for conversion.

### -Quality

Quality setting (CRF for ffmpeg, quality for handbrake). Defaults to 23 for ffmpeg.


## Outputs

System.String. Path to the converted video file.


## Examples

### Example 1

`powershell
Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv"
        
        Converts input.mp4 to output.mkv using ffmpeg with default settings.
``

### Example 2

`powershell
Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv" -Codec "hevc" -Quality 20
        
        Converts to HEVC codec with quality 20.
``

### Example 3

`powershell
Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv" -UseHandbrake -Preset "Fast 1080p30"
        
        Converts using Handbrake with a preset.
``

## Source

Defined in: ..\profile.d\media-tools.ps1
