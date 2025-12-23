# content-tools.ps1

Content download and management tools fragment.

## Overview

The `content-tools.ps1` fragment provides wrapper functions for content download and management tools:

- **Video Downloaders**: yt-dlp for YouTube and other video platforms
- **Gallery Downloaders**: gallery-dl for image galleries
- **Playlist Downloaders**: Download entire playlists with yt-dlp
- **Web Archivers**: monolith for creating standalone HTML archives
- **Platform-Specific**: twitchdownloader for Twitch content

## Dependencies

- `bootstrap.ps1` - Core bootstrap functions
- `env.ps1` - Environment configuration

## Functions

### Download-Video

Downloads videos using yt-dlp.

**Syntax:**

```powershell
Download-Video -Url <string> [-OutputPath <string>] [-Format <string>] [-AudioOnly] [<CommonParameters>]
```

**Parameters:**

- `Url` (Required) - URL of the video to download.
- `OutputPath` - Directory to save the video. Defaults to current directory.
- `Format` - Video format/quality. Defaults to best available.
- `AudioOnly` - Download audio only (extract audio).

**Examples:**

```powershell
# Download a video from YouTube
Download-Video -Url "https://www.youtube.com/watch?v=example"

# Download audio only
Download-Video -Url "https://www.youtube.com/watch?v=example" -AudioOnly

# Download with specific format
Download-Video -Url "https://www.youtube.com/watch?v=example" -Format "best[height<=720]"
```

**Installation:**

```powershell
scoop install yt-dlp-nightly
```

---

### Download-Gallery

Downloads image galleries.

**Syntax:**

```powershell
Download-Gallery -Url <string> [-OutputPath <string>] [<CommonParameters>]
```

**Parameters:**

- `Url` (Required) - URL of the gallery to download.
- `OutputPath` - Directory to save images. Defaults to current directory.

**Examples:**

```powershell
# Download all images from a gallery
Download-Gallery -Url "https://example.com/gallery"

# Download to specific directory
Download-Gallery -Url "https://example.com/gallery" -OutputPath "C:\Downloads\Gallery"
```

**Installation:**

```powershell
scoop install gallery-dl
```

---

### Download-Playlist

Downloads playlists.

**Syntax:**

```powershell
Download-Playlist -Url <string> [-OutputPath <string>] [-AudioOnly] [<CommonParameters>]
```

**Parameters:**

- `Url` (Required) - URL of the playlist to download.
- `OutputPath` - Directory to save videos. Defaults to current directory.
- `AudioOnly` - Download audio only for all videos in playlist.

**Examples:**

```powershell
# Download all videos from a YouTube playlist
Download-Playlist -Url "https://www.youtube.com/playlist?list=example"

# Download audio only from playlist
Download-Playlist -Url "https://www.youtube.com/playlist?list=example" -AudioOnly
```

**Installation:**

```powershell
scoop install yt-dlp-nightly
```

---

### Archive-WebPage

Archives web pages.

**Syntax:**

```powershell
Archive-WebPage -Url <string> [-OutputFile <string>] [<CommonParameters>]
```

**Parameters:**

- `Url` (Required) - URL of the web page to archive.
- `OutputFile` - Path to save the archived HTML file. Defaults to page title with .html extension.

**Examples:**

```powershell
# Archive a web page as standalone HTML
Archive-WebPage -Url "https://example.com/article"

# Archive to specific file
Archive-WebPage -Url "https://example.com/article" -OutputFile "archived.html"
```

**Installation:**

```powershell
scoop install monolith
```

---

### Download-Twitch

Downloads Twitch content.

**Syntax:**

```powershell
Download-Twitch -Url <string> [-OutputPath <string>] [-Quality <string>] [<CommonParameters>]
```

**Parameters:**

- `Url` (Required) - URL of the Twitch content to download.
- `OutputPath` - Directory to save the video. Defaults to current directory.
- `Quality` - Video quality. Defaults to best available.

**Examples:**

```powershell
# Download a Twitch VOD
Download-Twitch -Url "https://www.twitch.tv/videos/123456789"

# Download with specific quality
Download-Twitch -Url "https://www.twitch.tv/videos/123456789" -Quality "1080p"
```

**Installation:**

```powershell
scoop install twitchdownloader-cli
```

---

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions check for tool availability using `Test-CachedCommand`
- Missing tools display installation hints using `Write-MissingToolWarning`
- Functions return `$null` when tools are unavailable
- No errors are thrown for missing tools (graceful degradation)
- Download-Twitch prefers twitchdownloader-cli but falls back to twitchdownloader

## Installation

Install required tools using Scoop:

```powershell
# Install all content tools
scoop install yt-dlp-nightly gallery-dl monolith twitchdownloader-cli

# Or install individually
scoop install yt-dlp-nightly      # Video downloader (YouTube, Vimeo, etc.)
scoop install gallery-dl          # Image gallery downloader
scoop install monolith            # Web page archiver
scoop install twitchdownloader-cli # Twitch downloader
```

## Testing

The fragment includes comprehensive test coverage:

- **Unit tests**: Individual function tests with mocking
- **Integration tests**: Fragment loading and function registration
- **Performance tests**: Load time and function execution performance

Run tests:

```powershell
# Run unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/content-tools.ps1

# Run integration tests
Invoke-Pester tests/integration/tools/content-tools.tests.ps1

# Run performance tests
Invoke-Pester tests/performance/content-tools-performance.tests.ps1
```

## Notes

- All functions are idempotent and can be safely called multiple times
- Functions use `Set-AgentModeFunction` for registration
- Download-Video and Download-Playlist use yt-dlp which supports many video platforms
- Download-Gallery uses gallery-dl which supports various image hosting sites
- Archive-WebPage creates standalone HTML files with embedded resources
- Download-Twitch supports VODs, clips, and streams
- All download functions create output directories if they don't exist
- Functions handle errors gracefully and provide helpful error messages
