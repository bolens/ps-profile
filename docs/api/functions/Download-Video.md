# Download-Video

## Synopsis

Downloads videos using yt-dlp.

## Description

Downloads videos from various platforms using yt-dlp (youtube-dl fork). Supports YouTube, Vimeo, and many other video platforms.

## Signature

```powershell
Download-Video
```

## Parameters

### -Url

URL of the video to download.

### -OutputPath

Directory to save the video. Defaults to current directory.

### -Format

Video format/quality. Defaults to best available.

### -AudioOnly

Download audio only (extract audio).


## Outputs

System.String. Path to the downloaded file.


## Examples

### Example 1

`powershell
Download-Video -Url "https://www.youtube.com/watch?v=example"
        
        Downloads a video from YouTube.
``

### Example 2

`powershell
Download-Video -Url "https://www.youtube.com/watch?v=example" -AudioOnly
        
        Downloads audio only from a video.
``

## Source

Defined in: ..\profile.d\content-tools.ps1
