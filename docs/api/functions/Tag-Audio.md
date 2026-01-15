# Tag-Audio

## Synopsis

Tags audio files with metadata.

## Description

Tags audio files using mp3tag, picard, or tagscanner. Launches the appropriate GUI tool for tagging audio files.

## Signature

```powershell
Tag-Audio
```

## Parameters

### -AudioPath

Path to the audio file or directory containing audio files.

### -Tool

Tagging tool to use: mp3tag, picard, or tagscanner. Defaults to mp3tag.


## Examples

### Example 1

`powershell
Tag-Audio -AudioPath "song.mp3"
        
        Opens mp3tag with the specified audio file.
``

### Example 2

`powershell
Tag-Audio -AudioPath "C:\Music" -Tool "picard"
        
        Opens MusicBrainz Picard with the specified directory.
``

## Source

Defined in: ..\profile.d\media-tools.ps1
