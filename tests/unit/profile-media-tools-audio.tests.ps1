# ===============================================
# profile-media-tools-audio.tests.ps1
# Unit tests for Tag-Audio and Rip-CD functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'media-tools.ps1')

    $script:TestRoot = New-TestTempDirectory -Prefix 'MediaToolsAudio'
    $script:TestAudioFile = Join-Path $script:TestRoot 'test-audio.mp3'
    $script:TestOutputDir = Join-Path $script:TestRoot 'ripped'
    Set-Content -Path $script:TestAudioFile -Value 'test content' -Encoding utf8
}

Describe 'media-tools.ps1 - Tag-Audio' {
    BeforeEach {
        Clear-TestStartProcessCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Reset-TestStartProcessMock
        Mark-TestCommandsUnavailable -CommandNames @('mp3tag', 'picard', 'tagscanner')
    }

    Context 'Tool not available' {
        It 'Returns null when mp3tag is not available' {
            $result = Tag-Audio -AudioPath $script:TestAudioFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Path validation' {
        It 'Returns error when path does not exist' {
            $missingFile = Join-Path $script:TestRoot 'nonexistent.mp3'

            $result = Tag-Audio -AudioPath $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Launches mp3tag with audio file' {
            Setup-AvailableCommandMock -CommandName 'mp3tag'

            Tag-Audio -AudioPath $script:TestAudioFile -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'mp3tag'
            $capture.ArgumentList | Should -Contain $script:TestAudioFile
        }

        It 'Launches picard when specified' {
            Setup-AvailableCommandMock -CommandName 'picard'

            Tag-Audio -AudioPath $script:TestAudioFile -Tool 'picard' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'picard'
        }

        It 'Launches tagscanner when specified' {
            Setup-AvailableCommandMock -CommandName 'tagscanner'

            Tag-Audio -AudioPath $script:TestAudioFile -Tool 'tagscanner' -ErrorAction SilentlyContinue | Out-Null

            $capture = Get-TestStartProcessCapture
            $capture.FilePath | Should -Be 'tagscanner'
        }

        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'mp3tag'
            Set-TestStartProcessFailure -Message 'Access denied'

            { Tag-Audio -AudioPath $script:TestAudioFile -ErrorAction Stop } | Should -Throw '*Access denied*'
        }
    }
}

Describe 'media-tools.ps1 - Rip-CD' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'cyanrip'
    }

    Context 'Tool not available' {
        It 'Returns null when cyanrip is not available' {
            $result = Rip-CD -OutputPath $script:TestOutputDir -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls cyanrip with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'cyanrip' -ExitCode 0

            $outputDir = Join-Path $script:TestRoot 'ripped-new'
            Rip-CD -OutputPath $outputDir -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-o'
            $args | Should -Contain $outputDir
            $args | Should -Contain '-f'
            $args | Should -Contain 'flac'
        }

        It 'Calls cyanrip with custom format' {
            Setup-CapturingCommandMock -CommandName 'cyanrip' -ExitCode 0

            Rip-CD -OutputPath $script:TestOutputDir -Format 'mp3' -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-f'
            $args | Should -Contain 'mp3'
        }

        It 'Calls cyanrip with quality setting' {
            Setup-CapturingCommandMock -CommandName 'cyanrip' -ExitCode 0

            Rip-CD -OutputPath $script:TestOutputDir -Format 'mp3' -Quality 2 -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-q'
            $args | Should -Contain '2'
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'cyanrip' -ExitCode 0

            $result = Rip-CD -OutputPath $script:TestOutputDir -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestOutputDir
        }

        It 'Handles cyanrip execution errors' {
            Setup-CapturingCommandMock -CommandName 'cyanrip' -ExitCode 1

            { Rip-CD -OutputPath $script:TestOutputDir -Confirm:$false -ErrorAction Stop } | Should -Throw
        }
    }
}
