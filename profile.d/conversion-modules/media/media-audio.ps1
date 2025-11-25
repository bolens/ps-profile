# ===============================================
# Audio media format conversion utilities
# Audio conversion and video to audio extraction
# ===============================================

<#
.SYNOPSIS
    Initializes audio media format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for audio format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudio {
    # Audio convert
    Set-Item -Path Function:Global:_Convert-Audio -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            ffmpeg -i $InputPath $OutputPath 2>$null
        }
        catch {
            Write-Error "Failed to convert audio: $_"
        }
    } -Force

    # Video to audio
    Set-Item -Path Function:Global:_ConvertFrom-VideoToAudio -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'mp3') }
            ffmpeg -i $InputPath -vn -acodec libmp3lame $OutputPath 2>$null
        }
        catch {
            Write-Error "Failed to extract audio from video: $_"
        }
    } -Force
}

# Convert audio formats
<#
.SYNOPSIS
    Converts audio file formats.
.DESCRIPTION
    Uses ffmpeg to convert an audio file from one format to another.
.PARAMETER InputPath
    The path to the input audio file.
.PARAMETER OutputPath
    The path for the output audio file with desired format.
#>
function Convert-Audio {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    _Convert-Audio @PSBoundParameters
}
Set-Alias -Name audio-convert -Value Convert-Audio -ErrorAction SilentlyContinue

# Extract audio from video
<#
.SYNOPSIS
    Extracts audio from video file.
.DESCRIPTION
    Uses ffmpeg to extract audio track from a video file as MP3.
.PARAMETER InputPath
    The path to the video file.
.PARAMETER OutputPath
    The path for the output audio file. If not specified, uses input path with .mp3 extension.
#>
function ConvertFrom-VideoToAudio {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    _ConvertFrom-VideoToAudio @PSBoundParameters
}
Set-Alias -Name video-to-audio -Value ConvertFrom-VideoToAudio -ErrorAction SilentlyContinue

