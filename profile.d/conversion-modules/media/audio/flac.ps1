# ===============================================
# FLAC Audio Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes FLAC audio format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for FLAC format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudioFlac {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-AudioFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaAudioCommon
    }

    # FLAC conversions
    Set-Item -Path Function:Global:_ConvertFrom-FlacToWav -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.flac$', '.wav' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'pcm_s16le'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-FlacToMp3 -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.flac$', '.mp3' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libmp3lame' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-FlacToOgg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.flac$', '.ogg' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libvorbis' -Options @{ 'q:a' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-FlacToAac -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.flac$', '.aac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'aac' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-FlacToOpus -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.flac$', '.opus' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libopus' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force
}

# FLAC conversion functions
<#
.SYNOPSIS
    Converts FLAC audio to WAV format.
.DESCRIPTION
    Converts a FLAC audio file to WAV format using FFmpeg.
.PARAMETER InputPath
    Path to the input FLAC file.
.PARAMETER OutputPath
    Path for the output WAV file. If not specified, uses input path with .wav extension.
.EXAMPLE
    ConvertFrom-FlacToWav -InputPath "audio.flac" -OutputPath "audio.wav"
#>
function ConvertFrom-FlacToWav {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-FlacToWav -ErrorAction SilentlyContinue) {
            _ConvertFrom-FlacToWav @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-FlacToWav not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FLAC to WAV: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'flac-to-wav' -Target 'ConvertFrom-FlacToWav'
}
else {
    Set-Alias -Name flac-to-wav -Value ConvertFrom-FlacToWav -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts FLAC audio to MP3 format.
.DESCRIPTION
    Converts a FLAC audio file to MP3 format using FFmpeg.
.PARAMETER InputPath
    Path to the input FLAC file.
.PARAMETER OutputPath
    Path for the output MP3 file. If not specified, uses input path with .mp3 extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 192).
.EXAMPLE
    ConvertFrom-FlacToMp3 -InputPath "audio.flac" -OutputPath "audio.mp3" -Bitrate 256
#>
function ConvertFrom-FlacToMp3 {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-FlacToMp3 -ErrorAction SilentlyContinue) {
            _ConvertFrom-FlacToMp3 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-FlacToMp3 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FLAC to MP3: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'flac-to-mp3' -Target 'ConvertFrom-FlacToMp3'
}
else {
    Set-Alias -Name flac-to-mp3 -Value ConvertFrom-FlacToMp3 -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts FLAC audio to OGG Vorbis format.
.DESCRIPTION
    Converts a FLAC audio file to OGG Vorbis format using FFmpeg.
.PARAMETER InputPath
    Path to the input FLAC file.
.PARAMETER OutputPath
    Path for the output OGG file. If not specified, uses input path with .ogg extension.
.PARAMETER Quality
    Audio quality (0-10, default: 5). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-FlacToOgg -InputPath "audio.flac" -OutputPath "audio.ogg" -Quality 7
#>
function ConvertFrom-FlacToOgg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-FlacToOgg -ErrorAction SilentlyContinue) {
            _ConvertFrom-FlacToOgg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-FlacToOgg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FLAC to OGG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'flac-to-ogg' -Target 'ConvertFrom-FlacToOgg'
}
else {
    Set-Alias -Name flac-to-ogg -Value ConvertFrom-FlacToOgg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts FLAC audio to AAC format.
.DESCRIPTION
    Converts a FLAC audio file to AAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input FLAC file.
.PARAMETER OutputPath
    Path for the output AAC file. If not specified, uses input path with .aac extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-FlacToAac -InputPath "audio.flac" -OutputPath "audio.aac" -Bitrate 192
#>
function ConvertFrom-FlacToAac {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-FlacToAac -ErrorAction SilentlyContinue) {
            _ConvertFrom-FlacToAac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-FlacToAac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FLAC to AAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'flac-to-aac' -Target 'ConvertFrom-FlacToAac'
}
else {
    Set-Alias -Name flac-to-aac -Value ConvertFrom-FlacToAac -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts FLAC audio to Opus format.
.DESCRIPTION
    Converts a FLAC audio file to Opus format using FFmpeg.
.PARAMETER InputPath
    Path to the input FLAC file.
.PARAMETER OutputPath
    Path for the output Opus file. If not specified, uses input path with .opus extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-FlacToOpus -InputPath "audio.flac" -OutputPath "audio.opus" -Bitrate 192
#>
function ConvertFrom-FlacToOpus {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-FlacToOpus -ErrorAction SilentlyContinue) {
            _ConvertFrom-FlacToOpus @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-FlacToOpus not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert FLAC to Opus: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'flac-to-opus' -Target 'ConvertFrom-FlacToOpus'
}
else {
    Set-Alias -Name flac-to-opus -Value ConvertFrom-FlacToOpus -ErrorAction SilentlyContinue
}

