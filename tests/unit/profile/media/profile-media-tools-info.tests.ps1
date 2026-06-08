# ===============================================
# profile-media-tools-info.tests.ps1
# Unit tests for Get-MediaInfo and Merge-MKV functions
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'media-tools.ps1')

    $script:TestMediaDir = New-TestTempDirectory -Prefix 'MediaInfo'
    $script:TestMediaFile = Join-Path $script:TestMediaDir 'test-video.mp4'
    Set-Content -Path $script:TestMediaFile -Value 'test content'

    $script:TestMkvDir = New-TestTempDirectory -Prefix 'MkvMerge'
    $script:TestInputFile1 = Join-Path $script:TestMkvDir 'part1.mkv'
    $script:TestInputFile2 = Join-Path $script:TestMkvDir 'part2.mkv'
    Set-Content -Path $script:TestInputFile1 -Value 'test content 1'
    Set-Content -Path $script:TestInputFile2 -Value 'test content 2'
    $script:TestOutputMkv = Get-TestArtifactPath -FileName 'output.mkv'
}

Describe 'media-tools.ps1 - Get-MediaInfo' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($command in @('mediainfo', 'MediaInfo')) {
            Set-TestCommandAvailabilityState -CommandName $command -Available $false
            Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Tool not available' {
        It 'Returns null when mediainfo is not available' {
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Media file validation' {
        It 'Returns error when media file does not exist' {
            $missingFile = Join-Path (New-TestTempDirectory -Prefix 'MediaMissing') 'nonexistent.mp4'

            $result = Get-MediaInfo -MediaPath $missingFile -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls mediainfo with default format' {
            Setup-CapturingCommandMock -CommandName 'mediainfo' -Output 'Media information'

            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain $script:TestMediaFile
            $result | Should -Be 'Media information'
        }

        It 'Calls mediainfo with JSON format' {
            Setup-CapturingCommandMock -CommandName 'mediainfo' -Output '{"media": "info"}'

            Get-MediaInfo -MediaPath $script:TestMediaFile -OutputFormat 'json' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--Output=JSON'
        }

        It 'Calls mediainfo with XML format' {
            Setup-CapturingCommandMock -CommandName 'mediainfo' -Output '<?xml version="1.0"?>'

            Get-MediaInfo -MediaPath $script:TestMediaFile -OutputFormat 'xml' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--Output=XML'
        }

        It 'Saves output to file when OutputPath is specified' {
            Setup-CapturingCommandMock -CommandName 'mediainfo' -Output '{"media": "info"}'

            $outputFile = Join-Path (New-TestTempDirectory -Prefix 'MediaInfoOut') 'info.json'
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -OutputFormat 'json' -OutputPath $outputFile -ErrorAction SilentlyContinue

            Test-Path -LiteralPath $outputFile | Should -Be $true
            $result | Should -Be $outputFile
        }

        It 'Handles mediainfo execution errors' {
            Setup-CapturingCommandMock -CommandName 'mediainfo' -Output '' -ExitCode 1

            { Get-MediaInfo -MediaPath $script:TestMediaFile -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe 'media-tools.ps1 - Merge-MKV' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'mkvmerge' -Available $false
        Remove-Item -Path 'Function:\mkvmerge' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:mkvmerge' -Force -ErrorAction SilentlyContinue
    }

    Context 'Tool not available' {
        It 'Returns null when mkvmerge is not available' {
            $result = Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath $script:TestOutputMkv -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Input file validation' {
        It 'Returns error when input file does not exist' {
            $missingFile = Join-Path (New-TestTempDirectory -Prefix 'MkvMissing') 'nonexistent.mkv'

            $result = Merge-MKV -InputPaths @($missingFile) -OutputPath $script:TestOutputMkv -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls mkvmerge with correct arguments' {
            Setup-CapturingCommandMock -CommandName 'mkvmerge' -Output ''

            Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath $script:TestOutputMkv -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-o'
            $args | Should -Contain $script:TestOutputMkv
            $args | Should -Contain $script:TestInputFile1
            $args | Should -Contain $script:TestInputFile2
        }

        It 'Returns output path on success' {
            Setup-CapturingCommandMock -CommandName 'mkvmerge' -Output ''

            $result = Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath $script:TestOutputMkv -Confirm:$false -ErrorAction SilentlyContinue

            $result | Should -Be $script:TestOutputMkv
        }

        It 'Handles mkvmerge execution errors' {
            Setup-CapturingCommandMock -CommandName 'mkvmerge' -Output '' -ExitCode 1

            { Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath $script:TestOutputMkv -Confirm:$false -ErrorAction Stop } | Should -Throw
        }
    }
}
