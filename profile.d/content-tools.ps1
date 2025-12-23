# ===============================================
# content-tools.ps1
# Content download and management tools
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Content download and management tools fragment.

.DESCRIPTION
    Provides wrapper functions for content download and management tools:
    - Video downloaders: yt-dlp, bbdown, crunchy-cli, spotdl
    - Gallery downloaders: gallery-dl, ripme
    - Web archivers: monolith, cobalt
    - Platform-specific: twitchdownloader, svtplay-dl

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides content download and archival capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'content-tools') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Download-Video - Download videos with yt-dlp
    # ===============================================

    <#
    .SYNOPSIS
        Downloads videos using yt-dlp.
    
    .DESCRIPTION
        Downloads videos from various platforms using yt-dlp (youtube-dl fork).
        Supports YouTube, Vimeo, and many other video platforms.
    
    .PARAMETER Url
        URL of the video to download.
    
    .PARAMETER OutputPath
        Directory to save the video. Defaults to current directory.
    
    .PARAMETER Format
        Video format/quality. Defaults to best available.
    
    .PARAMETER AudioOnly
        Download audio only (extract audio).
    
    .EXAMPLE
        Download-Video -Url "https://www.youtube.com/watch?v=example"
        
        Downloads a video from YouTube.
    
    .EXAMPLE
        Download-Video -Url "https://www.youtube.com/watch?v=example" -AudioOnly
        
        Downloads audio only from a video.
    
    .OUTPUTS
        System.String. Path to the downloaded file.
    #>
    function Download-Video {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Url,
            
            [string]$OutputPath = (Get-Location).Path,
            
            [string]$Format,
            
            [switch]$AudioOnly
        )

        if (-not (Test-CachedCommand 'yt-dlp')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'yt-dlp-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'yt-dlp' -InstallHint $installHint
            }
            else {
                Write-Warning "yt-dlp is not installed. Install it with: scoop install yt-dlp-nightly"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $arguments = @('-o', (Join-Path $OutputPath '%(title)s.%(ext)s'))
        
        if ($AudioOnly) {
            $arguments += '-x', '--audio-format', 'mp3'
        }
        elseif ($Format) {
            $arguments += '-f', $Format
        }
        
        $arguments += $Url

        try {
            $output = & yt-dlp $arguments 2>&1
            if ($LASTEXITCODE -eq 0) {
                # Extract file path from output if possible
                $fileMatch = $output | Select-String -Pattern '\[download\].*?(\S+\.(mp4|webm|mkv|mp3))' | Select-Object -First 1
                if ($fileMatch) {
                    return $fileMatch.Matches[0].Groups[1].Value
                }
                return $OutputPath
            }
            else {
                Write-Error "Video download failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run yt-dlp: $_"
        }
    }

    # ===============================================
    # Download-Gallery - Download image galleries
    # ===============================================

    <#
    .SYNOPSIS
        Downloads image galleries.
    
    .DESCRIPTION
        Downloads images from galleries using gallery-dl.
        Supports various image hosting sites and social media platforms.
    
    .PARAMETER Url
        URL of the gallery to download.
    
    .PARAMETER OutputPath
        Directory to save images. Defaults to current directory.
    
    .EXAMPLE
        Download-Gallery -Url "https://example.com/gallery"
        
        Downloads all images from a gallery.
    #>
    function Download-Gallery {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Url,
            
            [string]$OutputPath = (Get-Location).Path
        )

        if (-not (Test-CachedCommand 'gallery-dl')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'gallery-dl' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'gallery-dl' -InstallHint $installHint
            }
            else {
                Write-Warning "gallery-dl is not installed. Install it with: scoop install gallery-dl"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $arguments = @('-D', $OutputPath, $Url)

        try {
            & gallery-dl $arguments 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Gallery downloaded to: $OutputPath" -ForegroundColor Green
            }
            else {
                Write-Error "Gallery download failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run gallery-dl: $_"
        }
    }

    # ===============================================
    # Download-Playlist - Download playlists
    # ===============================================

    <#
    .SYNOPSIS
        Downloads playlists.
    
    .DESCRIPTION
        Downloads entire playlists using yt-dlp.
        Supports YouTube playlists and similar formats.
    
    .PARAMETER Url
        URL of the playlist to download.
    
    .PARAMETER OutputPath
        Directory to save videos. Defaults to current directory.
    
    .PARAMETER AudioOnly
        Download audio only for all videos in playlist.
    
    .EXAMPLE
        Download-Playlist -Url "https://www.youtube.com/playlist?list=example"
        
        Downloads all videos from a YouTube playlist.
    #>
    function Download-Playlist {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Url,
            
            [string]$OutputPath = (Get-Location).Path,
            
            [switch]$AudioOnly
        )

        if (-not (Test-CachedCommand 'yt-dlp')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'yt-dlp-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'yt-dlp' -InstallHint $installHint
            }
            else {
                Write-Warning "yt-dlp is not installed. Install it with: scoop install yt-dlp-nightly"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $arguments = @('-o', (Join-Path $OutputPath '%(playlist_title)s/%(title)s.%(ext)s'))
        
        if ($AudioOnly) {
            $arguments += '-x', '--audio-format', 'mp3'
        }
        
        $arguments += $Url

        try {
            & yt-dlp $arguments 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Playlist downloaded to: $OutputPath" -ForegroundColor Green
            }
            else {
                Write-Error "Playlist download failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run yt-dlp: $_"
        }
    }

    # ===============================================
    # Archive-WebPage - Archive web pages
    # ===============================================

    <#
    .SYNOPSIS
        Archives web pages.
    
    .DESCRIPTION
        Creates standalone HTML archives of web pages using monolith.
        Preserves page structure, images, and styling.
    
    .PARAMETER Url
        URL of the web page to archive.
    
    .PARAMETER OutputFile
        Path to save the archived HTML file. Defaults to page title with .html extension.
    
    .EXAMPLE
        Archive-WebPage -Url "https://example.com/article"
        
        Archives a web page as standalone HTML.
    #>
    function Archive-WebPage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Url,
            
            [string]$OutputFile
        )

        if (-not (Test-CachedCommand 'monolith')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'monolith' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'monolith' -InstallHint $installHint
            }
            else {
                Write-Warning "monolith is not installed. Install it with: scoop install monolith"
            }
            return
        }

        if (-not $OutputFile) {
            $OutputFile = Join-Path (Get-Location).Path 'archived-page.html'
        }

        try {
            & monolith $Url '-o' $OutputFile 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                return $OutputFile
            }
            else {
                Write-Error "Web page archiving failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run monolith: $_"
        }
    }

    # ===============================================
    # Download-Twitch - Download Twitch content
    # ===============================================

    <#
    .SYNOPSIS
        Downloads Twitch content.
    
    .DESCRIPTION
        Downloads Twitch videos or clips using twitchdownloader.
        Supports VODs, clips, and streams.
    
    .PARAMETER Url
        URL of the Twitch content to download.
    
    .PARAMETER OutputPath
        Directory to save the video. Defaults to current directory.
    
    .PARAMETER Quality
        Video quality. Defaults to best available.
    
    .EXAMPLE
        Download-Twitch -Url "https://www.twitch.tv/videos/123456789"
        
        Downloads a Twitch VOD.
    #>
    function Download-Twitch {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Url,
            
            [string]$OutputPath = (Get-Location).Path,
            
            [string]$Quality
        )

        # Check for twitchdownloader or twitchdownloader-cli
        $twitchCmd = if (Test-CachedCommand 'twitchdownloader-cli') {
            'twitchdownloader-cli'
        }
        elseif (Test-CachedCommand 'twitchdownloader') {
            'twitchdownloader'
        }
        else {
            $null
        }

        if (-not $twitchCmd) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'twitchdownloader-cli' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'twitchdownloader' -InstallHint $installHint
            }
            else {
                Write-Warning "twitchdownloader is not installed. Install it with: scoop install twitchdownloader-cli"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        $arguments = @('-u', $Url, '-o', $OutputPath)
        
        if ($Quality) {
            $arguments += '-q', $Quality
        }

        try {
            & $twitchCmd $arguments 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Twitch content downloaded to: $OutputPath" -ForegroundColor Green
            }
            else {
                Write-Error "Twitch download failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run twitchdownloader: $_"
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Download-Video' -Body ${function:Download-Video}
        Set-AgentModeFunction -Name 'Download-Gallery' -Body ${function:Download-Gallery}
        Set-AgentModeFunction -Name 'Download-Playlist' -Body ${function:Download-Playlist}
        Set-AgentModeFunction -Name 'Archive-WebPage' -Body ${function:Archive-WebPage}
        Set-AgentModeFunction -Name 'Download-Twitch' -Body ${function:Download-Twitch}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Download-Video -Value ${function:Download-Video} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Download-Gallery -Value ${function:Download-Gallery} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Download-Playlist -Value ${function:Download-Playlist} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Archive-WebPage -Value ${function:Archive-WebPage} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Download-Twitch -Value ${function:Download-Twitch} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'content-tools'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: content-tools" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load content-tools fragment: $($_.Exception.Message)"
    }
}
