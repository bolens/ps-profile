# Download-Gallery

## Synopsis

Downloads image galleries.

## Description

Downloads images from galleries using gallery-dl. Supports various image hosting sites and social media platforms.

## Signature

```powershell
Download-Gallery
```

## Parameters

### -Url

URL of the gallery to download.

### -OutputPath

Directory to save images. Defaults to current directory.


## Examples

### Example 1

`powershell
Download-Gallery -Url "https://example.com/gallery"
        
        Downloads all images from a gallery.
``

## Source

Defined in: ..\profile.d\content-tools.ps1
