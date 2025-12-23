# ===============================================
# OGG Vorbis Audio Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes OGG Vorbis audio format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for OGG Vorbis format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudioOgg {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-AudioFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaAudioCommon
    }

    # OGG Vorbis conversions
    Set-Item -Path Function:Global:_ConvertFrom-OggToWav -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ogg$', '.wav' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'pcm_s16le'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OggToMp3 -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ogg$', '.mp3' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libmp3lame' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OggToFlac -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ogg$', '.flac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'flac'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OggToAac -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ogg$', '.aac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'aac' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OggToOpus -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.ogg$', '.opus' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libopus' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force
}

# OGG Vorbis conversion functions
<#
.SYNOPSIS
    Converts OGG Vorbis audio to WAV format.
.DESCRIPTION
    Converts an OGG Vorbis audio file to WAV format using FFmpeg.
.PARAMETER InputPath
    Path to the input OGG file.
.PARAMETER OutputPath
    Path for the output WAV file. If not specified, uses input path with .wav extension.
.EXAMPLE
    ConvertFrom-OggToWav -InputPath "audio.ogg" -OutputPath "audio.wav"
#>
function ConvertFrom-OggToWav {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OggToWav -ErrorAction SilentlyContinue) {
            _ConvertFrom-OggToWav @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OggToWav not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert OGG to WAV: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ogg-to-wav' -Target 'ConvertFrom-OggToWav'
}
else {
    Set-Alias -Name ogg-to-wav -Value ConvertFrom-OggToWav -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts OGG Vorbis audio to MP3 format.
.DESCRIPTION
    Converts an OGG Vorbis audio file to MP3 format using FFmpeg.
.PARAMETER InputPath
    Path to the input OGG file.
.PARAMETER OutputPath
    Path for the output MP3 file. If not specified, uses input path with .mp3 extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 192).
.EXAMPLE
    ConvertFrom-OggToMp3 -InputPath "audio.ogg" -OutputPath "audio.mp3"
#>
function ConvertFrom-OggToMp3 {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OggToMp3 -ErrorAction SilentlyContinue) {
            _ConvertFrom-OggToMp3 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OggToMp3 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert OGG to MP3: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ogg-to-mp3' -Target 'ConvertFrom-OggToMp3'
}
else {
    Set-Alias -Name ogg-to-mp3 -Value ConvertFrom-OggToMp3 -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts OGG Vorbis audio to FLAC format.
.DESCRIPTION
    Converts an OGG Vorbis audio file to FLAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input OGG file.
.PARAMETER OutputPath
    Path for the output FLAC file. If not specified, uses input path with .flac extension.
.EXAMPLE
    ConvertFrom-OggToFlac -InputPath "audio.ogg" -OutputPath "audio.flac"
#>
function ConvertFrom-OggToFlac {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OggToFlac -ErrorAction SilentlyContinue) {
            _ConvertFrom-OggToFlac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OggToFlac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert OGG to FLAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ogg-to-flac' -Target 'ConvertFrom-OggToFlac'
}
else {
    Set-Alias -Name ogg-to-flac -Value ConvertFrom-OggToFlac -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts OGG Vorbis audio to AAC format.
.DESCRIPTION
    Converts an OGG Vorbis audio file to AAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input OGG file.
.PARAMETER OutputPath
    Path for the output AAC file. If not specified, uses input path with .aac extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-OggToAac -InputPath "audio.ogg" -OutputPath "audio.aac"
#>
function ConvertFrom-OggToAac {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OggToAac -ErrorAction SilentlyContinue) {
            _ConvertFrom-OggToAac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OggToAac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert OGG to AAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ogg-to-aac' -Target 'ConvertFrom-OggToAac'
}
else {
    Set-Alias -Name ogg-to-aac -Value ConvertFrom-OggToAac -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts OGG Vorbis audio to Opus format.
.DESCRIPTION
    Converts an OGG Vorbis audio file to Opus format using FFmpeg.
.PARAMETER InputPath
    Path to the input OGG file.
.PARAMETER OutputPath
    Path for the output Opus file. If not specified, uses input path with .opus extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-OggToOpus -InputPath "audio.ogg" -OutputPath "audio.opus"
#>
function ConvertFrom-OggToOpus {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OggToOpus -ErrorAction SilentlyContinue) {
            _ConvertFrom-OggToOpus @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OggToOpus not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert OGG to Opus: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'ogg-to-opus' -Target 'ConvertFrom-OggToOpus'
}
else {
    Set-Alias -Name ogg-to-opus -Value ConvertFrom-OggToOpus -ErrorAction SilentlyContinue
}

