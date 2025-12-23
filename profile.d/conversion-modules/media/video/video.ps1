# ===============================================
# Video media format conversion utilities
# Video to GIF conversion
# ===============================================

<#
.SYNOPSIS
    Initializes video media format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for video format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaVideo {
    # Video to GIF
    Set-Item -Path Function:Global:_ConvertFrom-VideoToGif -Value {
        param([string]$InputPath, [string]$OutputPath)
        try {
            if (-not $OutputPath) { $OutputPath = [IO.Path]::ChangeExtension($InputPath, 'gif') }
            ffmpeg -i $InputPath -vf "fps=10,scale=320:-1:flags=lanczos" $OutputPath 2>$null
        }
        catch {
            Write-Error "Failed to convert video to GIF: $_"
        }
    } -Force
}

# Convert video to GIF
<#
.SYNOPSIS
    Converts video to GIF.
.DESCRIPTION
    Uses ffmpeg to convert a video file to animated GIF.
.PARAMETER InputPath
    The path to the video file.
.PARAMETER OutputPath
    The path for the output GIF file. If not specified, uses input path with .gif extension.
#>
function ConvertFrom-VideoToGif {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    _ConvertFrom-VideoToGif @PSBoundParameters
}
Set-Alias -Name video-to-gif -Value ConvertFrom-VideoToGif -ErrorAction SilentlyContinue

