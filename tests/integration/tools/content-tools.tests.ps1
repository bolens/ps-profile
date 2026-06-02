# ===============================================
# content-tools.tests.ps1
# Integration tests for content-tools.ps1 fragment
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'content-tools.ps1')
}

Describe 'content-tools.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'content-tools.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'content-tools.ps1')
            . (Join-Path $script:ProfileDir 'content-tools.ps1')
        } | Should -Not -Throw
    }
}

Describe 'content-tools.ps1 - Function Registration' {
    It 'Registers Download-Video function' {
        Get-Command -Name 'Download-Video' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Download-Gallery function' {
        Get-Command -Name 'Download-Gallery' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Download-Playlist function' {
        Get-Command -Name 'Download-Playlist' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Archive-WebPage function' {
        Get-Command -Name 'Archive-WebPage' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Download-Twitch function' {
        Get-Command -Name 'Download-Twitch' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'content-tools.ps1 - Graceful Degradation' {
    BeforeEach {
        if ($global:CollectedMissingToolWarnings) {
            $global:CollectedMissingToolWarnings.Clear()
        }
        if ($global:MissingToolWarnings) {
            $global:MissingToolWarnings.Clear()
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        foreach ($cmd in @('yt-dlp', 'gallery-dl', 'monolith', 'twitchdownloader-cli', 'twitchdownloader')) {
            Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
        }
    }

    It 'Download-Video handles missing tool gracefully' {
        $output = & { Download-Video -Url 'https://youtube.com/watch?v=test' } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'yt-dlp not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'yt-dlp'
    }

    It 'Download-Gallery handles missing tool gracefully' {
        $output = & { Download-Gallery -Url 'https://example.com/gallery' } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gallery-dl not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'gallery-dl'
    }

    It 'Download-Playlist handles missing tool gracefully' {
        $output = & { Download-Playlist -Url 'https://youtube.com/playlist?list=test' } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'yt-dlp not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'yt-dlp'
    }

    It 'Archive-WebPage handles missing tool gracefully' {
        $output = & { Archive-WebPage -Url 'https://example.com/page' } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'monolith not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'monolith'
    }

    It 'Download-Twitch handles missing tool gracefully' {
        $output = & { Download-Twitch -Url 'https://twitch.tv/videos/123' } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'twitchdownloader not found'
        Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'twitchdownloader'
    }
}

