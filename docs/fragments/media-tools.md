# media-tools.ps1

Media processing and conversion tools fragment.

## Overview

The `media-tools.ps1` fragment provides wrapper functions for video and audio processing, conversion, and manipulation tools, including:

- **Video conversion** with ffmpeg and Handbrake
- **Audio extraction** from video files
- **Audio tagging** with mp3tag, Picard, and TagScanner
- **CD ripping** with cyanrip
- **Media information** retrieval with mediainfo
- **MKV file merging** with mkvmerge

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration

## Functions

### Convert-Video

Converts video files to different formats and codecs using ffmpeg or Handbrake.

**Syntax:**

```powershell
Convert-Video -InputPath <string> -OutputPath <string> [-Codec <string>] [-Preset <string>] [-UseHandbrake] [-Quality <int>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `InputPath` (Required) - Path to the input video file.
- `OutputPath` (Required) - Path to the output video file.
- `Codec` - Video codec to use (e.g., h264, hevc, vp9). Defaults to h264.
- `Preset` - Handbrake preset to use (if using handbrake). Ignored if using ffmpeg.
- `UseHandbrake` - Use Handbrake instead of ffmpeg for conversion.
- `Quality` - Quality setting (CRF for ffmpeg, quality for handbrake). Defaults to 23 for ffmpeg.

**Examples:**

```powershell
# Convert video using ffmpeg
Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv"

# Convert to HEVC codec with custom quality
Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv" -Codec "hevc" -Quality 20

# Convert using Handbrake with preset
Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv" -UseHandbrake -Preset "Fast 1080p30"
```

**Installation:**

```powershell
# For ffmpeg
scoop install ffmpeg

# For Handbrake
scoop install handbrake-cli
```

---

### Extract-Audio

Extracts audio track from a video file and saves it as an audio file.

**Syntax:**

```powershell
Extract-Audio -InputPath <string> -OutputPath <string> [-AudioCodec <string>] [-Bitrate <string>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `InputPath` (Required) - Path to the input video file.
- `OutputPath` (Required) - Path to the output audio file.
- `AudioCodec` - Audio codec to use (mp3, flac, wav, aac, opus). Defaults to mp3.
- `Bitrate` - Audio bitrate (for lossy codecs). Defaults to 192k for mp3.

**Examples:**

```powershell
# Extract audio as MP3
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3"

# Extract audio as FLAC
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.flac" -AudioCodec "flac"

# Extract with custom bitrate
Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3" -Bitrate "320k"
```

**Installation:**

```powershell
scoop install ffmpeg
```

---

### Tag-Audio

Tags audio files with metadata using mp3tag, Picard, or TagScanner.

**Syntax:**

```powershell
Tag-Audio -AudioPath <string> [-Tool <string>] [<CommonParameters>]
```

**Parameters:**

- `AudioPath` (Required) - Path to the audio file or directory containing audio files.
- `Tool` - Tagging tool to use: mp3tag, picard, or tagscanner. Defaults to mp3tag.

**Examples:**

```powershell
# Tag audio file with mp3tag
Tag-Audio -AudioPath "song.mp3"

# Tag directory with MusicBrainz Picard
Tag-Audio -AudioPath "C:\Music" -Tool "picard"

# Tag with TagScanner
Tag-Audio -AudioPath "album" -Tool "tagscanner"
```

**Installation:**

```powershell
scoop install mp3tag      # Audio tag editor
scoop install picard      # MusicBrainz tagger
scoop install tagscanner  # Audio tag editor
```

---

### Rip-CD

Rips audio tracks from a CD using cyanrip.

**Syntax:**

```powershell
Rip-CD -OutputPath <string> [-Format <string>] [-Quality <int>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `OutputPath` (Required) - Directory where ripped audio files will be saved.
- `Format` - Output format: flac, mp3, wav, opus. Defaults to flac.
- `Quality` - Quality setting (for lossy formats). Defaults to 0 (highest quality).

**Examples:**

```powershell
# Rip CD to FLAC format
Rip-CD -OutputPath "C:\Music\Album"

# Rip CD to MP3 format with highest quality
Rip-CD -OutputPath "C:\Music\Album" -Format "mp3" -Quality 0
```

**Installation:**

```powershell
scoop install cyanrip
```

---

### Get-MediaInfo

Gets detailed technical information about a media file using mediainfo.

**Syntax:**

```powershell
Get-MediaInfo -MediaPath <string> [-OutputFormat <string>] [-OutputPath <string>] [<CommonParameters>]
```

**Parameters:**

- `MediaPath` (Required) - Path to the media file.
- `OutputFormat` - Output format: text, json, xml. Defaults to text.
- `OutputPath` - Optional path to save the information to a file.

**Examples:**

```powershell
# Get media information
Get-MediaInfo -MediaPath "video.mp4"

# Get media information as JSON
Get-MediaInfo -MediaPath "video.mp4" -OutputFormat "json"

# Save media information to file
Get-MediaInfo -MediaPath "video.mp4" -OutputFormat "json" -OutputPath "info.json"
```

**Installation:**

```powershell
scoop install mediainfo
```

---

### Merge-MKV

Merges multiple MKV files into one using mkvmerge.

**Syntax:**

```powershell
Merge-MKV -InputPaths <string[]> -OutputPath <string> [-WhatIf] [-Confirm] [<CommonParameters>]
```

**Parameters:**

- `InputPaths` (Required) - Array of input MKV file paths.
- `OutputPath` (Required) - Path to the output merged MKV file.

**Examples:**

```powershell
# Merge two MKV files
Merge-MKV -InputPaths @("part1.mkv", "part2.mkv") -OutputPath "complete.mkv"

# Merge multiple parts
Merge-MKV -InputPaths @("part1.mkv", "part2.mkv", "part3.mkv") -OutputPath "complete.mkv"
```

**Installation:**

```powershell
scoop install mkvtoolnix
```

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)

## Installation

Install required tools using Scoop:

```powershell
# Install all media tools
scoop install ffmpeg handbrake-cli mkvtoolnix mediainfo mp3tag picard tagscanner cyanrip

# Or install individually
scoop install ffmpeg          # Video/audio conversion
scoop install handbrake-cli   # Video transcoding
scoop install mkvtoolnix      # MKV manipulation
scoop install mediainfo       # Media information
scoop install mp3tag          # Audio tagging
scoop install picard          # MusicBrainz tagging
scoop install tagscanner      # Audio tagging
scoop install cyanrip         # CD ripping
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:

```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/media-tools.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/media-tools.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/media-tools-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` for registration
- Video conversion functions support both ffmpeg and Handbrake
- Audio tagging functions launch GUI applications
- CD ripping requires a CD drive and appropriate permissions
- MKV merging preserves all tracks and metadata from source files
