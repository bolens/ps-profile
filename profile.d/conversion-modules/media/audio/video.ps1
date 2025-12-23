# ===============================================
# Video to Audio Extraction Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes video to audio extraction utility functions.
.DESCRIPTION
    Sets up internal conversion functions for extracting audio from video files.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudioVideo {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Ensure-Ffmpeg -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaAudioCommon
    }

    # Video to audio extraction
    Set-Item -Path Function:Global:_ConvertFrom-VideoToAudio -Value {
        param([string]$InputPath, [string]$OutputPath, [string]$Format = 'mp3', [int]$Bitrate = 192)
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            _Ensure-Ffmpeg
            
            if (-not $OutputPath) {
                $OutputPath = [IO.Path]::ChangeExtension($InputPath, $Format)
            }
            
            $codecMap = @{
                'mp3'  = 'libmp3lame'
                'aac'  = 'aac'
                'ogg'  = 'libvorbis'
                'opus' = 'libopus'
                'flac' = 'flac'
                'wav'  = 'pcm_s16le'
            }
            
            $codec = if ($codecMap.ContainsKey($Format)) { $codecMap[$Format] } else { 'libmp3lame' }
            
            $ffmpegArgs = @('-i', $InputPath, '-vn', '-y', '-acodec', $codec)
            
            if ($Format -in @('mp3', 'aac', 'opus')) {
                $ffmpegArgs += @('-b:a', "${Bitrate}k")
            }
            elseif ($Format -eq 'ogg') {
                $ffmpegArgs += @('-q:a', '5')
            }
            
            $ffmpegArgs += $OutputPath
            
            $errorOutput = & ffmpeg $ffmpegArgs 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $tail = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "ffmpeg failed with exit code $exitCode while extracting audio from video '$InputPath' to '$OutputPath' as format '$Format'. Error: $tail"
            }
        }
        catch {
            Write-Error "Failed to extract audio from video: $($_.Exception.Message)"
            throw
        }
    } -Force
}

# Video to audio conversion function
<#
.SYNOPSIS
    Extracts audio from video file.
.DESCRIPTION
    Uses FFmpeg to extract audio track from a video file in the specified format.
.PARAMETER InputPath
    Path to the video file.
.PARAMETER OutputPath
    Path for the output audio file. If not specified, uses input path with format extension.
.PARAMETER Format
    Output audio format: mp3, aac, ogg, opus, flac, or wav (default: mp3).
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 192). Used for mp3, aac, and opus formats.
.EXAMPLE
    ConvertFrom-VideoToAudio -InputPath "video.mp4" -OutputPath "audio.mp3" -Format mp3
#>
function ConvertFrom-VideoToAudio {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [ValidateSet('mp3', 'aac', 'ogg', 'opus', 'flac', 'wav')]
        [string]$Format = 'mp3',
        [int]$Bitrate = 192
    )
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-VideoToAudio -ErrorAction SilentlyContinue) {
            _ConvertFrom-VideoToAudio @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-VideoToAudio not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to extract audio from video: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'video-to-audio' -Target 'ConvertFrom-VideoToAudio'
}
else {
    Set-Alias -Name video-to-audio -Value ConvertFrom-VideoToAudio -ErrorAction SilentlyContinue
}

