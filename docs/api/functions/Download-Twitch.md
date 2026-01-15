# Download-Twitch

## Synopsis

Downloads Twitch content.

## Description

Downloads Twitch videos or clips using twitchdownloader. Supports VODs, clips, and streams.

## Signature

```powershell
Download-Twitch
```

## Parameters

### -Url

URL of the Twitch content to download.

### -OutputPath

Directory to save the video. Defaults to current directory.

### -Quality

Video quality. Defaults to best available.


## Examples

### Example 1

`powershell
Download-Twitch -Url "https://www.twitch.tv/videos/123456789"
        
        Downloads a Twitch VOD.
``

## Source

Defined in: ..\profile.d\content-tools.ps1
