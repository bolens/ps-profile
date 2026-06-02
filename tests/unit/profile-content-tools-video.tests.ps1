# ===============================================
# profile-content-tools-video.tests.ps1
# Unit tests for Download-Video and Download-Playlist functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'content-tools.ps1')
    $script:TestOutputDir = New-TestTempDirectory -Prefix 'ContentToolsVideo'
}

Describe 'content-tools.ps1 - Download-Video' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'yt-dlp'
    }

    Context 'Tool not available' {
        It 'Returns null when yt-dlp is not available' {
            $result = Download-Video -Url 'https://youtube.com/watch?v=test' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls yt-dlp with URL and output path' {
            Setup-CapturingCommandMock -CommandName 'yt-dlp' -Output '[download] video.mp4'

            Download-Video -Url 'https://youtube.com/watch?v=test' -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-o'
            $args | Should -Contain 'https://youtube.com/watch?v=test'
        }

        It 'Calls yt-dlp with audio-only option' {
            Setup-CapturingCommandMock -CommandName 'yt-dlp' -Output '[download] audio.mp3'

            Download-Video -Url 'https://youtube.com/watch?v=test' -OutputPath $script:TestOutputDir -AudioOnly -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-x'
            $args | Should -Contain '--audio-format'
            $args | Should -Contain 'mp3'
        }

        It 'Calls yt-dlp with format option' {
            Setup-CapturingCommandMock -CommandName 'yt-dlp' -Output '[download] video.mp4'

            Download-Video -Url 'https://youtube.com/watch?v=test' -OutputPath $script:TestOutputDir -Format 'best' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-f'
            $args | Should -Contain 'best'
        }

        It 'Handles yt-dlp execution errors' {
            Setup-CapturingCommandMock -CommandName 'yt-dlp' -ExitCode 1 -Output 'Error: Video unavailable'

            { Download-Video -Url 'https://youtube.com/watch?v=test' -OutputPath $script:TestOutputDir -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe 'content-tools.ps1 - Download-Playlist' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'yt-dlp'
    }

    Context 'Tool not available' {
        It 'Returns null when yt-dlp is not available' {
            $result = Download-Playlist -Url 'https://youtube.com/playlist?list=test' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls yt-dlp with playlist URL' {
            Setup-CapturingCommandMock -CommandName 'yt-dlp' -Output '[download] Playlist downloaded'

            Download-Playlist -Url 'https://youtube.com/playlist?list=test' -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'https://youtube.com/playlist?list=test'
        }

        It 'Calls yt-dlp with audio-only option for playlist' {
            Setup-CapturingCommandMock -CommandName 'yt-dlp' -Output '[download] Playlist downloaded'

            Download-Playlist -Url 'https://youtube.com/playlist?list=test' -OutputPath $script:TestOutputDir -AudioOnly -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-x'
            $args | Should -Contain '--audio-format'
            $args | Should -Contain 'mp3'
        }
    }
}
