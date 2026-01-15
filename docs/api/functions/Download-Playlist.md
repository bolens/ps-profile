# Download-Playlist

## Synopsis

Downloads playlists.

## Description

Downloads entire playlists using yt-dlp. Supports YouTube playlists and similar formats.

## Signature

```powershell
Download-Playlist
```

## Parameters

### -Url

URL of the playlist to download.

### -OutputPath

Directory to save videos. Defaults to current directory.

### -AudioOnly

Download audio only for all videos in playlist.


## Examples

### Example 1

`powershell
Download-Playlist -Url "https://www.youtube.com/playlist?list=example"
        
        Downloads all videos from a YouTube playlist.
``

## Source

Defined in: ..\profile.d\content-tools.ps1
