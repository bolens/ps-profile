# ===============================================
# Audio media format conversion utilities - Common Helpers
# Shared helper functions for all audio format conversions
# ===============================================

<#
.SYNOPSIS
    Initializes common audio conversion helper functions.
.DESCRIPTION
    Sets up shared helper functions used by all audio format conversion modules.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudioCommon {
    # Helper function to check for FFmpeg
    Set-Item -Path Function:Global:_Ensure-Ffmpeg -Value {
        if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
            throw "ffmpeg command not found. Please install FFmpeg to use audio conversion functions. " +
            "Install with: scoop install ffmpeg (Windows), apt install ffmpeg (Linux), or brew install ffmpeg (macOS)"
        }
    } -Force

    # Helper function for generic audio conversion
    Set-Item -Path Function:Global:_Convert-AudioFormat -Value {
        param(
            [string]$InputPath,
            [string]$OutputPath,
            [string]$Codec = 'copy',
            [hashtable]$Options = @{}
        )
        try {
            if (-not $InputPath) { throw "InputPath parameter is required" }
            if (-not ($InputPath -and -not [string]::IsNullOrWhiteSpace($InputPath) -and (Test-Path -LiteralPath $InputPath))) { throw "Input file not found: $InputPath" }
            
            _Ensure-Ffmpeg
            
            if (-not $OutputPath) {
                throw "OutputPath parameter is required"
            }
            
            # Build FFmpeg command
            $ffmpegArgs = @('-i', $InputPath, '-y')  # -y to overwrite output
            
            # Add codec if specified
            if ($Codec -ne 'copy') {
                $ffmpegArgs += @('-acodec', $Codec)
            }
            else {
                $ffmpegArgs += @('-acodec', 'copy')
            }
            
            # Add custom options
            foreach ($key in $Options.Keys) {
                $ffmpegArgs += @("-$key", $Options[$key])
            }
            
            $ffmpegArgs += $OutputPath
            
            # Execute FFmpeg
            $errorOutput = & ffmpeg $ffmpegArgs 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                $tail = if ($errorOutput) { ($errorOutput | Out-String).Trim() } else { "Unknown error" }
                throw "ffmpeg failed with exit code $exitCode while converting audio from '$InputPath' to '$OutputPath' using codec '$Codec'. Error: $tail"
            }
        }
        catch {
            Write-Error "Failed to convert audio: $($_.Exception.Message)"
            throw
        }
    } -Force
}

