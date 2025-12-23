# ===============================================
# AAC Audio Format Conversion Utilities
# ===============================================

<#
.SYNOPSIS
    Initializes AAC audio format conversion utility functions.
.DESCRIPTION
    Sets up internal conversion functions for AAC format conversions.
    This function is called automatically by Ensure-FileConversion-Media.
.NOTES
    This is an internal initialization function and should not be called directly.
#>
function Initialize-FileConversion-MediaAudioAac {
    # Ensure common helpers are initialized
    if (-not (Get-Command _Convert-AudioFormat -ErrorAction SilentlyContinue)) {
        Initialize-FileConversion-MediaAudioCommon
    }

    # AAC conversions
    Set-Item -Path Function:Global:_ConvertFrom-AacToWav -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.aac$', '.wav' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'pcm_s16le'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-AacToMp3 -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.aac$', '.mp3' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libmp3lame' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-AacToFlac -Value {
        param([string]$InputPath, [string]$OutputPath)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.aac$', '.flac' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'flac'
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-AacToOgg -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.aac$', '.ogg' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libvorbis' -Options @{ 'q:a' = $Quality }
    } -Force

    Set-Item -Path Function:Global:_ConvertFrom-AacToOpus -Value {
        param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
        if (-not $OutputPath) { $OutputPath = $InputPath -replace '\.aac$', '.opus' }
        _Convert-AudioFormat -InputPath $InputPath -OutputPath $OutputPath -Codec 'libopus' -Options @{ 'b:a' = "${Bitrate}k" }
    } -Force
}

# AAC conversion functions
<#
.SYNOPSIS
    Converts AAC audio to WAV format.
.DESCRIPTION
    Converts an AAC audio file to WAV format using FFmpeg.
.PARAMETER InputPath
    Path to the input AAC file.
.PARAMETER OutputPath
    Path for the output WAV file. If not specified, uses input path with .wav extension.
.EXAMPLE
    ConvertFrom-AacToWav -InputPath "audio.aac" -OutputPath "audio.wav"
#>
function ConvertFrom-AacToWav {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AacToWav -ErrorAction SilentlyContinue) {
            _ConvertFrom-AacToWav @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AacToWav not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AAC to WAV: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aac-to-wav' -Target 'ConvertFrom-AacToWav'
}
else {
    Set-Alias -Name aac-to-wav -Value ConvertFrom-AacToWav -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AAC audio to MP3 format.
.DESCRIPTION
    Converts an AAC audio file to MP3 format using FFmpeg.
.PARAMETER InputPath
    Path to the input AAC file.
.PARAMETER OutputPath
    Path for the output MP3 file. If not specified, uses input path with .mp3 extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 192).
.EXAMPLE
    ConvertFrom-AacToMp3 -InputPath "audio.aac" -OutputPath "audio.mp3"
#>
function ConvertFrom-AacToMp3 {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 192)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AacToMp3 -ErrorAction SilentlyContinue) {
            _ConvertFrom-AacToMp3 @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AacToMp3 not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AAC to MP3: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aac-to-mp3' -Target 'ConvertFrom-AacToMp3'
}
else {
    Set-Alias -Name aac-to-mp3 -Value ConvertFrom-AacToMp3 -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AAC audio to FLAC format.
.DESCRIPTION
    Converts an AAC audio file to FLAC format using FFmpeg.
.PARAMETER InputPath
    Path to the input AAC file.
.PARAMETER OutputPath
    Path for the output FLAC file. If not specified, uses input path with .flac extension.
.EXAMPLE
    ConvertFrom-AacToFlac -InputPath "audio.aac" -OutputPath "audio.flac"
#>
function ConvertFrom-AacToFlac {
    param([string]$InputPath, [string]$OutputPath)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AacToFlac -ErrorAction SilentlyContinue) {
            _ConvertFrom-AacToFlac @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AacToFlac not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AAC to FLAC: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aac-to-flac' -Target 'ConvertFrom-AacToFlac'
}
else {
    Set-Alias -Name aac-to-flac -Value ConvertFrom-AacToFlac -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AAC audio to OGG Vorbis format.
.DESCRIPTION
    Converts an AAC audio file to OGG Vorbis format using FFmpeg.
.PARAMETER InputPath
    Path to the input AAC file.
.PARAMETER OutputPath
    Path for the output OGG file. If not specified, uses input path with .ogg extension.
.PARAMETER Quality
    Audio quality (0-10, default: 5). Higher values mean better quality but larger files.
.EXAMPLE
    ConvertFrom-AacToOgg -InputPath "audio.aac" -OutputPath "audio.ogg"
#>
function ConvertFrom-AacToOgg {
    param([string]$InputPath, [string]$OutputPath, [int]$Quality = 5)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AacToOgg -ErrorAction SilentlyContinue) {
            _ConvertFrom-AacToOgg @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AacToOgg not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AAC to OGG: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aac-to-ogg' -Target 'ConvertFrom-AacToOgg'
}
else {
    Set-Alias -Name aac-to-ogg -Value ConvertFrom-AacToOgg -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Converts AAC audio to Opus format.
.DESCRIPTION
    Converts an AAC audio file to Opus format using FFmpeg.
.PARAMETER InputPath
    Path to the input AAC file.
.PARAMETER OutputPath
    Path for the output Opus file. If not specified, uses input path with .opus extension.
.PARAMETER Bitrate
    Audio bitrate in kbps (default: 128).
.EXAMPLE
    ConvertFrom-AacToOpus -InputPath "audio.aac" -OutputPath "audio.opus"
#>
function ConvertFrom-AacToOpus {
    param([string]$InputPath, [string]$OutputPath, [int]$Bitrate = 128)
    if (-not $global:FileConversionMediaInitialized) { Ensure-FileConversion-Media }
    try {
        if (Get-Command _ConvertFrom-AacToOpus -ErrorAction SilentlyContinue) {
            _ConvertFrom-AacToOpus @PSBoundParameters
        }
        else {
            Write-Error "Internal conversion function _ConvertFrom-AacToOpus not available" -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to convert AAC to Opus: $_" -ErrorAction SilentlyContinue
    }
}
# Aliases (using Set-AgentModeAlias if available, otherwise Set-Alias)
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aac-to-opus' -Target 'ConvertFrom-AacToOpus'
}
else {
    Set-Alias -Name aac-to-opus -Value ConvertFrom-AacToOpus -ErrorAction SilentlyContinue
}

