# ===============================================
# Opus Audio Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes Opus audio format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for Opus format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudioOpus {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-AudioFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaAudioCommon
    }

    # Opus conversions
    Set-Item -Path Function:Global:_ConvertFrom-OpusToWav -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.opus$', '.wav' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'pcm_s16le'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OpusToMp3 -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.opus$', '.mp3' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libmp3lame' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OpusToFlac -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.opus$', '.flac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'flac'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OpusToOgg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.opus$', '.ogg' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libvorbis' -Options @{ 'q:a' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-OpusToAac -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.opus$', '.aac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'aac' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force
}

# Opus conversion functions
<#
.SYNOPSIS
    Converts Opus audio to WAV format.
.DESCRIPTION
    Converts an Opus audio file to WAV format using FFmpeg.
.PARAMETER InputPath
    Path to the input Opus file.
.PARAMETER OutputPath
    Path for the output WAV file. If not specified, uses input path with .wav extension.
.EXAMPLE
    ConvertFrom-OpusToWav -InputPath "audio.opus" -OutputPath "audio.wav"
#>
function ConvertFrom-OpusToWav {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OpusToWav -ErrorAction SilentlyContinue) {
            _ConvertFrom-OpusToWav @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OpusToWav not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Opus to WAV: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'opus-to-wav' -Target 'ConvertFrom-OpusToWav'
}
else {
    Set-Alias -Name opus-to-wav -Value ConvertFrom-OpusToWav -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Opus audio to MP3 format.
.DESCRIPTION
    Converts an Opus audio file to MP3 format using FFmpeg.
.PARAMETER InputPath
    Path to the input Opus file.
.PARAMETER OutputPath
    Path for the output MP3 file. If not specified, uses input path with .mp3 extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 192).
.EXAMPLE
    ConvertFrom-OpusToMp3 -InputPath "audio.opus" -OutputPath "audio.mp3"
#>
function ConvertFrom-OpusToMp3 {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OpusToMp3 -ErrorAction SilentlyContinue) {
            _ConvertFrom-OpusToMp3 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OpusToMp3 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Opus to MP3: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'opus-to-mp3' -Target 'ConvertFrom-OpusToMp3'
}
else {
    Set-Alias -Name opus-to-mp3 -Value ConvertFrom-OpusToMp3 -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Opus audio to FLAC format.
.DESCRIPTION
    Converts an Opus audio file to FLAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input Opus file.
.PARAMETER OutputPath
    Path for the output FLAC file. If not specified, uses input path with .flac extension.
.EXAMPLE
    ConvertFrom-OpusToFlac -InputPath "audio.opus" -OutputPath "audio.flac"
#>
function ConvertFrom-OpusToFlac {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OpusToFlac -ErrorAction SilentlyContinue) {
            _ConvertFrom-OpusToFlac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OpusToFlac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Opus to FLAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'opus-to-flac' -Target 'ConvertFrom-OpusToFlac'
}
else {
    Set-Alias -Name opus-to-flac -Value ConvertFrom-OpusToFlac -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Opus audio to OGG Vorbis format.
.DESCRIPTION
    Converts an Opus audio file to OGG Vorbis format using FFmpeg.
.PARAMETER InputPath
    Path to the input Opus file.
.PARAMETER OutputPath
    Path for the output OGG file. If not specified, uses input path with .ogg extension.
.PARAMETER Quality
    Audio quality (0-10, default: 5). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-OpusToOgg -InputPath "audio.opus" -OutputPath "audio.ogg"
#>
function ConvertFrom-OpusToOgg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OpusToOgg -ErrorAction SilentlyContinue) {
            _ConvertFrom-OpusToOgg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OpusToOgg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Opus to OGG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'opus-to-ogg' -Target 'ConvertFrom-OpusToOgg'
}
else {
    Set-Alias -Name opus-to-ogg -Value ConvertFrom-OpusToOgg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts Opus audio to AAC format.
.DESCRIPTION
    Converts an Opus audio file to AAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input Opus file.
.PARAMETER OutputPath
    Path for the output AAC file. If not specified, uses input path with .aac extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-OpusToAac -InputPath "audio.opus" -OutputPath "audio.aac"
#>
function ConvertFrom-OpusToAac {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-OpusToAac -ErrorAction SilentlyContinue) {
            _ConvertFrom-OpusToAac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-OpusToAac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert Opus to AAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'opus-to-aac' -Target 'ConvertFrom-OpusToAac'
}
else {
    Set-Alias -Name opus-to-aac -Value ConvertFrom-OpusToAac -ErrorAction SilentlyContinue
}

