# ===============================================
# profile-media-tools-video.tests.ps1
# Unit tests for Convert-Video and Extract-Audio functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'media-tools.ps1')

    $script:TestRoot = New-TestTempDirectory -Prefix 'MediaToolsVideo'
    $script:TestInputFile = Join-Path $script:TestRoot 'test-input.mp4'
    $script:TestVideoFile = Join-Path $script:TestRoot 'test-video.mp4'
    Set-Content -Path $script:TestInputFile -Value 'test content' -Encoding utf8
    Set-Content -Path $script:TestVideoFile -Value 'test content' -Encoding utf8
    $script:OutputMkv = Join-Path $script:TestRoot 'output.mkv'
    $script:OutputMp3 = Join-Path $script:TestRoot 'audio.mp3'
    $script:OutputFlac = Join-Path $script:TestRoot 'audio.flac'
}

Describe 'media-tools.ps1 - Convert-Video' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('ffmpeg', 'handbrake-cli', 'HandBrakeCLI')
    }

    Context 'Tool not available' {
        It 'Returns null when ffmpeg is not available' {
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns null when handbrake is not available' {
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -UseHandbrake -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Input file validation' {
        It 'Returns error when input file does not exist' {
            $missingFile = Join-Path $script:TestRoot 'nonexistent.mp4'

            $result = Convert-Video -InputPath $missingFile -OutputPath $script:OutputMkv -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'FFmpeg conversion' {
        It 'Calls ffmpeg with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 0

            Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-i'
            $args | Should -Contain $script:TestInputFile
            $args | Should -Contain $script:OutputMkv
        }

        It 'Calls ffmpeg with custom codec and quality' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 0

            Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -Codec 'hevc' -Quality 20 -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-c:v'
            $args | Should -Contain 'hevc'
            $args | Should -Contain '-crf'
            $args | Should -Contain '20'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 0

            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -Be $script:OutputMkv
        }

        It 'Handles ffmpeg execution errors' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 1

            { Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -Confirm:$false -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'Handbrake conversion' {
        It 'Calls handbrake-cli with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'handbrake-cli' -ExitCode 0

            Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -UseHandbrake -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-i'
            $args | Should -Contain $script:TestInputFile
            $args | Should -Contain '-o'
            $args | Should -Contain $script:OutputMkv
        }

        It 'Calls handbrake-cli with preset' {
            Setup-CapturingCommandMock -CommandName 'handbrake-cli' -ExitCode 0

            Convert-Video -InputPath $script:TestInputFile -OutputPath $script:OutputMkv -UseHandbrake -Preset 'Fast 1080p30' -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--preset'
            $args | Should -Contain 'Fast 1080p30'
        }
    }
}

Describe 'media-tools.ps1 - Extract-Audio' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'ffmpeg'
    }

    Context 'Tool not available' {
        It 'Returns null when ffmpeg is not available' {
            $result = Extract-Audio -InputPath $script:TestVideoFile -OutputPath $script:OutputMp3 -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Input file validation' {
        It 'Returns error when input file does not exist' {
            $missingFile = Join-Path $script:TestRoot 'nonexistent.mp4'

            $result = Extract-Audio -InputPath $missingFile -OutputPath $script:OutputMp3 -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls ffmpeg with correct arguments for MP3 extraction' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 0

            Extract-Audio -InputPath $script:TestVideoFile -OutputPath $script:OutputMp3 -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-i'
            $args | Should -Contain $script:TestVideoFile
            $args | Should -Contain '-vn'
            $args | Should -Contain '-acodec'
            $args | Should -Contain 'mp3'
            $args | Should -Contain $script:OutputMp3
        }

        It 'Calls ffmpeg with FLAC codec' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 0

            Extract-Audio -InputPath $script:TestVideoFile -OutputPath $script:OutputFlac -AudioCodec 'flac' -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-acodec'
            $args | Should -Contain 'flac'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 0

            $result = Extract-Audio -InputPath $script:TestVideoFile -OutputPath $script:OutputMp3 -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -Be $script:OutputMp3
        }

        It 'Handles ffmpeg execution errors' {
            Setup-CapturingCommandMock -CommandName 'ffmpeg' -ExitCode 1

            { Extract-Audio -InputPath $script:TestVideoFile -OutputPath $script:OutputMp3 -Confirm:$false -ErrorAction Stop } | Should -Throw
        }
    }
}
