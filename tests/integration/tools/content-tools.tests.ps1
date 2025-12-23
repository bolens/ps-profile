# ===============================================
# content-tools.tests.ps1
# Integration tests for content-tools.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
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
    It 'Download-Video handles missing tool gracefully' {
        { Download-Video -Url 'https://youtube.com/watch?v=test' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Download-Gallery handles missing tool gracefully' {
        { Download-Gallery -Url 'https://example.com/gallery' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Download-Playlist handles missing tool gracefully' {
        { Download-Playlist -Url 'https://youtube.com/playlist?list=test' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Archive-WebPage handles missing tool gracefully' {
        { Archive-WebPage -Url 'https://example.com/page' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Download-Twitch handles missing tool gracefully' {
        { Download-Twitch -Url 'https://twitch.tv/videos/123' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

