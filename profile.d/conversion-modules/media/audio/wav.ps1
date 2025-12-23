# ===============================================
# WAV Audio Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes WAV audio format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for WAV format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudioWav {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-AudioFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaAudioCommon
    }

    # WAV conversions
    Set-Item -Path Function:Global:_ConvertFrom-WavToMp3 -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.wav$', '.mp3' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libmp3lame' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WavToFlac -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.wav$', '.flac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'flac'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WavToOgg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.wav$', '.ogg' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libvorbis' -Options @{ 'q:a' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WavToAac -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.wav$', '.aac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'aac' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-WavToOpus -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.wav$', '.opus' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libopus' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force
}

# WAV conversion functions
<#
.SYNOPSIS
    Converts WAV audio to MP3 format.
.DESCRIPTION
    Converts a WAV audio file to MP3 format using FFmpeg.
.PARAMETER InputPath
    Path to the input WAV file.
.PARAMETER OutputPath
    Path for the output MP3 file. If not specified, uses input path with .mp3 extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 192).
.EXAMPLE
    ConvertFrom-WavToMp3 -InputPath "audio.wav" -OutputPath "audio.mp3"
#>
function ConvertFrom-WavToMp3 {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WavToMp3 -ErrorAction SilentlyContinue) {
            _ConvertFrom-WavToMp3 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WavToMp3 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WAV to MP3: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'wav-to-mp3' -Target 'ConvertFrom-WavToMp3'
}
else {
    Set-Alias -Name wav-to-mp3 -Value ConvertFrom-WavToMp3 -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts WAV audio to FLAC format.
.DESCRIPTION
    Converts a WAV audio file to FLAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input WAV file.
.PARAMETER OutputPath
    Path for the output FLAC file. If not specified, uses input path with .flac extension.
.EXAMPLE
    ConvertFrom-WavToFlac -InputPath "audio.wav" -OutputPath "audio.flac"
#>
function ConvertFrom-WavToFlac {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WavToFlac -ErrorAction SilentlyContinue) {
            _ConvertFrom-WavToFlac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WavToFlac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WAV to FLAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'wav-to-flac' -Target 'ConvertFrom-WavToFlac'
}
else {
    Set-Alias -Name wav-to-flac -Value ConvertFrom-WavToFlac -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts WAV audio to OGG Vorbis format.
.DESCRIPTION
    Converts a WAV audio file to OGG Vorbis format using FFmpeg.
.PARAMETER InputPath
    Path to the input WAV file.
.PARAMETER OutputPath
    Path for the output OGG file. If not specified, uses input path with .ogg extension.
.PARAMETER Quality
    Audio quality (0-10, default: 5). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-WavToOgg -InputPath "audio.wav" -OutputPath "audio.ogg"
#>
function ConvertFrom-WavToOgg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WavToOgg -ErrorAction SilentlyContinue) {
            _ConvertFrom-WavToOgg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WavToOgg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WAV to OGG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'wav-to-ogg' -Target 'ConvertFrom-WavToOgg'
}
else {
    Set-Alias -Name wav-to-ogg -Value ConvertFrom-WavToOgg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts WAV audio to AAC format.
.DESCRIPTION
    Converts a WAV audio file to AAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input WAV file.
.PARAMETER OutputPath
    Path for the output AAC file. If not specified, uses input path with .aac extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-WavToAac -InputPath "audio.wav" -OutputPath "audio.aac"
#>
function ConvertFrom-WavToAac {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WavToAac -ErrorAction SilentlyContinue) {
            _ConvertFrom-WavToAac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WavToAac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WAV to AAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'wav-to-aac' -Target 'ConvertFrom-WavToAac'
}
else {
    Set-Alias -Name wav-to-aac -Value ConvertFrom-WavToAac -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts WAV audio to Opus format.
.DESCRIPTION
    Converts a WAV audio file to Opus format using FFmpeg.
.PARAMETER InputPath
    Path to the input WAV file.
.PARAMETER OutputPath
    Path for the output Opus file. If not specified, uses input path with .opus extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-WavToOpus -InputPath "audio.wav" -OutputPath "audio.opus"
#>
function ConvertFrom-WavToOpus {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-WavToOpus -ErrorAction SilentlyContinue) {
            _ConvertFrom-WavToOpus @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-WavToOpus not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert WAV to Opus: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'wav-to-opus' -Target 'ConvertFrom-WavToOpus'
}
else {
    Set-Alias -Name wav-to-opus -Value ConvertFrom-WavToOpus -ErrorAction SilentlyContinue
}

