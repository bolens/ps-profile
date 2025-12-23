# ===============================================
# media-tools.ps1
# Media processing and conversion tools
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Media tools fragment for video/audio processing, conversion, and manipulation.

.DESCRIPTION
    Provides wrapper functions for media processing tools:
    - ffmpeg: Video/audio conversion and processing
    - handbrake: Video transcoding
    - mkvtoolnix: MKV file manipulation
    - mediainfo: Media file information
    - mp3tag/picard/tagscanner: Audio tagging
    - cyanrip: CD ripping
    - sox/flac/lame/wavpack: Audio encoding/processing

.NOTES
    All functions gracefully degrade when tools are not installed.
    Use Register-ToolWrapper for simple wrappers and custom functions for complex operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'media-tools') { return }
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
    # Convert-Video - Video conversion wrapper
    # ===============================================

    <#
    .SYNOPSIS
        Converts video files using ffmpeg or handbrake.
    
    .DESCRIPTION
        Converts video files to different formats and codecs. Supports both
        ffmpeg (flexible) and handbrake (preset-based) conversion.
    
    .PARAMETER InputPath
        Path to the input video file.
    
    .PARAMETER OutputPath
        Path to the output video file.
    
    .PARAMETER Codec
        Video codec to use (e.g., h264, hevc, vp9). Defaults to h264.
    
    .PARAMETER Preset
        Handbrake preset to use (if using handbrake). Ignored if using ffmpeg.
    
    .PARAMETER UseHandbrake
        Use Handbrake instead of ffmpeg for conversion.
    
    .PARAMETER Quality
        Quality setting (CRF for ffmpeg, quality for handbrake). Defaults to 23 for ffmpeg.
    
    .EXAMPLE
        Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv"
        
        Converts input.mp4 to output.mkv using ffmpeg with default settings.
    
    .EXAMPLE
        Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv" -Codec "hevc" -Quality 20
        
        Converts to HEVC codec with quality 20.
    
    .EXAMPLE
        Convert-Video -InputPath "input.mp4" -OutputPath "output.mkv" -UseHandbrake -Preset "Fast 1080p30"
        
        Converts using Handbrake with a preset.
    
    .OUTPUTS
        System.String. Path to the converted video file.
    #>
    function Convert-Video {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputPath,
            
            [Parameter(Mandatory = $true)]
            [string]$OutputPath,
            
            [string]$Codec = 'h264',
            
            [string]$Preset,
            
            [switch]$UseHandbrake,
            
            [int]$Quality = 23
        )

        if (-not (Test-Path -LiteralPath $InputPath)) {
            Write-Error "Input file not found: $InputPath"
            return
        }

        if ($UseHandbrake) {
            if (-not (Test-CachedCommand 'handbrake-cli') -and -not (Test-CachedCommand 'HandBrakeCLI')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'handbrake-cli' -RepoRoot $repoRoot
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -ToolName 'handbrake-cli' -InstallHint $installHint
                }
                else {
                    Write-Warning "handbrake-cli is not installed. Install it with: scoop install handbrake-cli"
                }
                return
            }

            $handbrakeCmd = if (Test-CachedCommand 'handbrake-cli') { 'handbrake-cli' } else { 'HandBrakeCLI' }

            if (-not $PSCmdlet.ShouldProcess($OutputPath, "Convert video using Handbrake")) {
                return
            }

            $arguments = @('-i', $InputPath, '-o', $OutputPath)
            
            if ($Preset) {
                $arguments += '--preset', $Preset
            }
            else {
                $arguments += '--encoder', $Codec
                if ($Quality) {
                    $arguments += '--quality', $Quality
                }
            }

            try {
                & $handbrakeCmd $arguments
                if ($LASTEXITCODE -eq 0) {
                    return $OutputPath
                }
                else {
                    Write-Error "Handbrake conversion failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to run handbrake: $_"
            }
        }
        else {
            if (-not (Test-CachedCommand 'ffmpeg')) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
                $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                    Get-ToolInstallHint -ToolName 'ffmpeg' -RepoRoot $repoRoot
                }
                if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                    Write-MissingToolWarning -ToolName 'ffmpeg' -InstallHint $installHint
                }
                else {
                    Write-Warning "ffmpeg is not installed. Install it with: scoop install ffmpeg"
                }
                return
            }

            if (-not $PSCmdlet.ShouldProcess($OutputPath, "Convert video using ffmpeg")) {
                return
            }

            $arguments = @('-i', $InputPath, '-c:v', $Codec, '-crf', $Quality, '-c:a', 'copy', '-y', $OutputPath)

            try {
                & ffmpeg $arguments 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    return $OutputPath
                }
                else {
                    Write-Error "FFmpeg conversion failed. Exit code: $LASTEXITCODE"
                }
            }
            catch {
                Write-Error "Failed to run ffmpeg: $_"
            }
        }
    }

    # ===============================================
    # Extract-Audio - Extract audio from video
    # ===============================================

    <#
    .SYNOPSIS
        Extracts audio from a video file.
    
    .DESCRIPTION
        Extracts audio track from a video file and saves it as an audio file.
        Supports various audio formats (mp3, flac, wav, etc.).
    
    .PARAMETER InputPath
        Path to the input video file.
    
    .PARAMETER OutputPath
        Path to the output audio file.
    
    .PARAMETER AudioCodec
        Audio codec to use (mp3, flac, wav, aac). Defaults to mp3.
    
    .PARAMETER Bitrate
        Audio bitrate (for lossy codecs). Defaults to 192k for mp3.
    
    .EXAMPLE
        Extract-Audio -InputPath "video.mp4" -OutputPath "audio.mp3"
        
        Extracts audio from video.mp4 and saves as audio.mp3.
    
    .EXAMPLE
        Extract-Audio -InputPath "video.mp4" -OutputPath "audio.flac" -AudioCodec "flac"
        
        Extracts audio as FLAC format.
    
    .OUTPUTS
        System.String. Path to the extracted audio file.
    #>
    function Extract-Audio {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$InputPath,
            
            [Parameter(Mandatory = $true)]
            [string]$OutputPath,
            
            [ValidateSet('mp3', 'flac', 'wav', 'aac', 'opus')]
            [string]$AudioCodec = 'mp3',
            
            [string]$Bitrate = '192k'
        )

        if (-not (Test-CachedCommand 'ffmpeg')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'ffmpeg' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'ffmpeg' -InstallHint $installHint
            }
            else {
                Write-Warning "ffmpeg is not installed. Install it with: scoop install ffmpeg"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $InputPath)) {
            Write-Error "Input file not found: $InputPath"
            return
        }

        if (-not $PSCmdlet.ShouldProcess($OutputPath, "Extract audio from video")) {
            return
        }

        $arguments = @('-i', $InputPath, '-vn', '-acodec', $AudioCodec)
        
        if ($AudioCodec -eq 'mp3' -or $AudioCodec -eq 'aac') {
            $arguments += '-b:a', $Bitrate
        }
        
        $arguments += '-y', $OutputPath

        try {
            & ffmpeg $arguments 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                return $OutputPath
            }
            else {
                Write-Error "Audio extraction failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run ffmpeg: $_"
        }
    }

    # ===============================================
    # Tag-Audio - Tag audio files
    # ===============================================

    <#
    .SYNOPSIS
        Tags audio files with metadata.
    
    .DESCRIPTION
        Tags audio files using mp3tag, picard, or tagscanner. Launches the
        appropriate GUI tool for tagging audio files.
    
    .PARAMETER AudioPath
        Path to the audio file or directory containing audio files.
    
    .PARAMETER Tool
        Tagging tool to use: mp3tag, picard, or tagscanner. Defaults to mp3tag.
    
    .EXAMPLE
        Tag-Audio -AudioPath "song.mp3"
        
        Opens mp3tag with the specified audio file.
    
    .EXAMPLE
        Tag-Audio -AudioPath "C:\Music" -Tool "picard"
        
        Opens MusicBrainz Picard with the specified directory.
    #>
    function Tag-Audio {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$AudioPath,
            
            [ValidateSet('mp3tag', 'picard', 'tagscanner')]
            [string]$Tool = 'mp3tag'
        )

        if (-not (Test-Path -LiteralPath $AudioPath)) {
            Write-Error "Path not found: $AudioPath"
            return
        }

        $toolName = switch ($Tool) {
            'mp3tag' { 'mp3tag' }
            'picard' { 'picard' }
            'tagscanner' { 'tagscanner' }
        }

        if (-not (Test-CachedCommand $toolName)) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName $toolName -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName $toolName -InstallHint $installHint
            }
            else {
                Write-Warning "$toolName is not installed. Install it with: scoop install $toolName"
            }
            return
        }

        try {
            Start-Process -FilePath $toolName -ArgumentList $AudioPath -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to launch $toolName : $_"
        }
    }

    # ===============================================
    # Rip-CD - CD ripping utilities
    # ===============================================

    <#
    .SYNOPSIS
        Rips audio from a CD.
    
    .DESCRIPTION
        Rips audio tracks from a CD using cyanrip. Supports various output
        formats and quality settings.
    
    .PARAMETER OutputPath
        Directory where ripped audio files will be saved.
    
    .PARAMETER Format
        Output format: flac, mp3, wav, opus. Defaults to flac.
    
    .PARAMETER Quality
        Quality setting (for lossy formats). Defaults to 0 (highest quality).
    
    .EXAMPLE
        Rip-CD -OutputPath "C:\Music\Album"
        
        Rips CD to FLAC format in the specified directory.
    
    .EXAMPLE
        Rip-CD -OutputPath "C:\Music\Album" -Format "mp3" -Quality 0
        
        Rips CD to MP3 format with highest quality.
    
    .OUTPUTS
        System.String. Path to the output directory.
    #>
    function Rip-CD {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$OutputPath,
            
            [ValidateSet('flac', 'mp3', 'wav', 'opus')]
            [string]$Format = 'flac',
            
            [int]$Quality = 0
        )

        if (-not (Test-CachedCommand 'cyanrip')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cyanrip' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'cyanrip' -InstallHint $installHint
            }
            else {
                Write-Warning "cyanrip is not installed. Install it with: scoop install cyanrip"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        if (-not $PSCmdlet.ShouldProcess($OutputPath, "Rip CD to $Format format")) {
            return
        }

        $arguments = @('-o', $OutputPath, '-f', $Format)
        
        if ($Quality -gt 0) {
            $arguments += '-q', $Quality
        }

        try {
            & cyanrip $arguments
            if ($LASTEXITCODE -eq 0) {
                return $OutputPath
            }
            else {
                Write-Error "CD ripping failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run cyanrip: $_"
        }
    }

    # ===============================================
    # Get-MediaInfo - Get media file information
    # ===============================================

    <#
    .SYNOPSIS
        Gets detailed information about a media file.
    
    .DESCRIPTION
        Retrieves detailed technical information about a media file using
        mediainfo. Returns information about video, audio, and container formats.
    
    .PARAMETER MediaPath
        Path to the media file.
    
    .PARAMETER OutputFormat
        Output format: text, json, xml. Defaults to text.
    
    .PARAMETER OutputPath
        Optional path to save the information to a file.
    
    .EXAMPLE
        Get-MediaInfo -MediaPath "video.mp4"
        
        Displays media information for video.mp4.
    
    .EXAMPLE
        Get-MediaInfo -MediaPath "video.mp4" -OutputFormat "json" -OutputPath "info.json"
        
        Saves media information as JSON to info.json.
    
    .OUTPUTS
        System.String. Media information in the specified format.
    #>
    function Get-MediaInfo {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$MediaPath,
            
            [ValidateSet('text', 'json', 'xml')]
            [string]$OutputFormat = 'text',
            
            [string]$OutputPath
        )

        if (-not (Test-Path -LiteralPath $MediaPath)) {
            Write-Error "Media file not found: $MediaPath"
            return
        }

        # Try mediainfo CLI first, then GUI
        $mediainfoCmd = $null
        if (Test-CachedCommand 'mediainfo') {
            $mediainfoCmd = 'mediainfo'
        }
        elseif (Test-CachedCommand 'MediaInfo') {
            $mediainfoCmd = 'MediaInfo'
        }
        else {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'mediainfo' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'mediainfo' -InstallHint $installHint
            }
            else {
                Write-Warning "mediainfo is not installed. Install it with: scoop install mediainfo"
            }
            return
        }

        $arguments = @()
        
        if ($OutputFormat -eq 'json') {
            $arguments += '--Output=JSON'
        }
        elseif ($OutputFormat -eq 'xml') {
            $arguments += '--Output=XML'
        }
        
        $arguments += $MediaPath

        try {
            $output = & $mediainfoCmd $arguments
            if ($LASTEXITCODE -eq 0) {
                if ($OutputPath) {
                    $output | Out-File -FilePath $OutputPath -Encoding utf8
                    return $OutputPath
                }
                else {
                    return $output
                }
            }
            else {
                Write-Error "Failed to get media info. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run mediainfo: $_"
        }
    }

    # ===============================================
    # Merge-MKV - Merge MKV files
    # ===============================================

    <#
    .SYNOPSIS
        Merges multiple MKV files into one.
    
    .DESCRIPTION
        Merges multiple MKV files using mkvmerge (from mkvtoolnix).
        Preserves all tracks and metadata from source files.
    
    .PARAMETER InputPaths
        Array of input MKV file paths.
    
    .PARAMETER OutputPath
        Path to the output merged MKV file.
    
    .EXAMPLE
        Merge-MKV -InputPaths @("part1.mkv", "part2.mkv") -OutputPath "complete.mkv"
        
        Merges part1.mkv and part2.mkv into complete.mkv.
    
    .OUTPUTS
        System.String. Path to the merged MKV file.
    #>
    function Merge-MKV {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$InputPaths,
            
            [Parameter(Mandatory = $true)]
            [string]$OutputPath
        )

        if (-not (Test-CachedCommand 'mkvmerge')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'mkvtoolnix' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -ToolName 'mkvmerge' -InstallHint $installHint
            }
            else {
                Write-Warning "mkvmerge is not installed. Install it with: scoop install mkvtoolnix"
            }
            return
        }

        foreach ($inputPath in $InputPaths) {
            if (-not (Test-Path -LiteralPath $inputPath)) {
                Write-Error "Input file not found: $inputPath"
                return
            }
        }

        if (-not $PSCmdlet.ShouldProcess($OutputPath, "Merge MKV files")) {
            return
        }

        $arguments = @('-o', $OutputPath) + $InputPaths

        try {
            & mkvmerge $arguments
            if ($LASTEXITCODE -eq 0) {
                return $OutputPath
            }
            else {
                Write-Error "MKV merge failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run mkvmerge: $_"
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Convert-Video' -Body ${function:Convert-Video}
        Set-AgentModeFunction -Name 'Extract-Audio' -Body ${function:Extract-Audio}
        Set-AgentModeFunction -Name 'Tag-Audio' -Body ${function:Tag-Audio}
        Set-AgentModeFunction -Name 'Rip-CD' -Body ${function:Rip-CD}
        Set-AgentModeFunction -Name 'Get-MediaInfo' -Body ${function:Get-MediaInfo}
        Set-AgentModeFunction -Name 'Merge-MKV' -Body ${function:Merge-MKV}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Convert-Video -Value ${function:Convert-Video} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Extract-Audio -Value ${function:Extract-Audio} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Tag-Audio -Value ${function:Tag-Audio} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Rip-CD -Value ${function:Rip-CD} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-MediaInfo -Value ${function:Get-MediaInfo} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Merge-MKV -Value ${function:Merge-MKV} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'media-tools'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: media-tools" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load media-tools fragment: $($_.Exception.Message)"
    }
}
