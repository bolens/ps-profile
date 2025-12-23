# ===============================================
# media-tools.tests.ps1
# Integration tests for media-tools.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'env.ps1')
    . (Join-Path $script:ProfileDir 'media-tools.ps1')
}

Describe 'media-tools.ps1 - Fragment Loading' {
    It 'Loads fragment without errors' {
        { . (Join-Path $script:ProfileDir 'media-tools.ps1') } | Should -Not -Throw
    }
    
    It 'Is idempotent (can be loaded multiple times)' {
        { 
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
            . (Join-Path $script:ProfileDir 'media-tools.ps1')
        } | Should -Not -Throw
    }
}

Describe 'media-tools.ps1 - Function Registration' {
    It 'Registers Convert-Video function' {
        Get-Command -Name 'Convert-Video' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Extract-Audio function' {
        Get-Command -Name 'Extract-Audio' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Tag-Audio function' {
        Get-Command -Name 'Tag-Audio' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Rip-CD function' {
        Get-Command -Name 'Rip-CD' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Get-MediaInfo function' {
        Get-Command -Name 'Get-MediaInfo' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It 'Registers Merge-MKV function' {
        Get-Command -Name 'Merge-MKV' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe 'media-tools.ps1 - Graceful Degradation' {
    It 'Convert-Video handles missing tool gracefully' {
        { Convert-Video -InputPath 'test.mp4' -OutputPath 'output.mkv' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Extract-Audio handles missing tool gracefully' {
        { Extract-Audio -InputPath 'test.mp4' -OutputPath 'audio.mp3' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Tag-Audio handles missing tool gracefully' {
        { Tag-Audio -AudioPath 'test.mp3' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Rip-CD handles missing tool gracefully' {
        { Rip-CD -OutputPath 'C:\Output' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Get-MediaInfo handles missing tool gracefully' {
        { Get-MediaInfo -MediaPath 'test.mp4' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
    
    It 'Merge-MKV handles missing tool gracefully' {
        { Merge-MKV -InputPaths @('part1.mkv', 'part2.mkv') -OutputPath 'output.mkv' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}

