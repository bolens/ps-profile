# ===============================================
# profile-content-tools-gallery.tests.ps1
# Unit tests for Download-Gallery, Archive-WebPage, and Download-Twitch functions
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'content-tools.ps1')
    $script:TestOutputDir = New-TestTempDirectory -Prefix 'ContentToolsGallery'
}

Describe 'content-tools.ps1 - Download-Gallery' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'gallery-dl'
    }

    Context 'Tool not available' {
        It 'Returns null when gallery-dl is not available' {
            $result = Download-Gallery -Url 'https://example.com/gallery' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls gallery-dl with URL and output path' {
            Setup-CapturingCommandMock -CommandName 'gallery-dl' -Output 'Downloaded gallery'

            Download-Gallery -Url 'https://example.com/gallery' -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-D'
            $args | Should -Contain $script:TestOutputDir
            $args | Should -Contain 'https://example.com/gallery'
        }

        It 'Handles gallery-dl execution errors' {
            Setup-CapturingCommandMock -CommandName 'gallery-dl' -ExitCode 1 -Output 'Error: Gallery not found'

            { Download-Gallery -Url 'https://example.com/gallery' -OutputPath $script:TestOutputDir -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe 'content-tools.ps1 - Archive-WebPage' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'monolith'
    }

    Context 'Tool not available' {
        It 'Returns null when monolith is not available' {
            $result = Archive-WebPage -Url 'https://example.com/page' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Calls monolith with URL and output file' {
            Setup-CapturingCommandMock -CommandName 'monolith' -ExitCode 0

            $outputFile = Join-Path $script:TestOutputDir 'archived.html'
            $result = Archive-WebPage -Url 'https://example.com/page' -OutputFile $outputFile -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'https://example.com/page'
            $args | Should -Contain '-o'
            $args | Should -Contain $outputFile
            $result | Should -Be $outputFile
        }

        It 'Uses default output file when not specified' {
            Setup-CapturingCommandMock -CommandName 'monolith' -ExitCode 0

            Push-Location $script:TestOutputDir
            try {
                $result = Archive-WebPage -Url 'https://example.com/page' -ErrorAction SilentlyContinue

                $args = Get-TestCommandInvocationArgsFlat
                $args | Should -Contain 'https://example.com/page'
                $args | Should -Contain '-o'
                $result | Should -Be (Join-Path $script:TestOutputDir 'archived-page.html')
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles monolith execution errors' {
            Setup-CapturingCommandMock -CommandName 'monolith' -ExitCode 1 -Output 'Error: Failed to archive'

            { Archive-WebPage -Url 'https://example.com/page' -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe 'content-tools.ps1 - Download-Twitch' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('twitchdownloader-cli', 'twitchdownloader')
    }

    Context 'Tool not available' {
        It 'Returns null when neither twitchdownloader nor twitchdownloader-cli is available' {
            $result = Download-Twitch -Url 'https://twitch.tv/videos/123' -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'twitchdownloader-cli available' {
        It 'Calls twitchdownloader-cli with URL' {
            Setup-CapturingCommandMock -CommandName 'twitchdownloader-cli' -Output 'Downloaded'
            Mark-TestCommandsUnavailable -CommandNames 'twitchdownloader'

            Download-Twitch -Url 'https://twitch.tv/videos/123' -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-u'
            $args | Should -Contain 'https://twitch.tv/videos/123'
            $args | Should -Contain '-o'
            $args | Should -Contain $script:TestOutputDir
        }

        It 'Calls twitchdownloader-cli with quality option' {
            Setup-CapturingCommandMock -CommandName 'twitchdownloader-cli' -Output 'Downloaded'
            Mark-TestCommandsUnavailable -CommandNames 'twitchdownloader'

            Download-Twitch -Url 'https://twitch.tv/videos/123' -OutputPath $script:TestOutputDir -Quality '1080p' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-q'
            $args | Should -Contain '1080p'
        }
    }

    Context 'twitchdownloader fallback' {
        It 'Calls twitchdownloader when twitchdownloader-cli not available' {
            Setup-CapturingCommandMock -CommandName 'twitchdownloader' -Output 'Downloaded'
            Mark-TestCommandsUnavailable -CommandNames 'twitchdownloader-cli'

            Download-Twitch -Url 'https://twitch.tv/videos/123' -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue | Out-Null

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-u'
            $args | Should -Contain 'https://twitch.tv/videos/123'
        }
    }
}
