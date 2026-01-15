# Get-MediaInfo

## Synopsis

Gets detailed information about a media file.

## Description

Retrieves detailed technical information about a media file using mediainfo. Returns information about video, audio, and container formats.

## Signature

```powershell
Get-MediaInfo
```

## Parameters

### -MediaPath

Path to the media file.

### -OutputFormat

Output format: text, json, xml. Defaults to text.

### -OutputPath

Optional path to save the information to a file.


## Outputs

System.String. Media information in the specified format.


## Examples

### Example 1

`powershell
Get-MediaInfo -MediaPath "video.mp4"
        
        Displays media information for video.mp4.
``

### Example 2

`powershell
Get-MediaInfo -MediaPath "video.mp4" -OutputFormat "json" -OutputPath "info.json"
        
        Saves media information as JSON to info.json.
``

## Source

Defined in: ..\profile.d\media-tools.ps1
