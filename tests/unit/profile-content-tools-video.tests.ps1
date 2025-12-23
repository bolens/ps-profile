# ===============================================
# profile-content-tools-video.tests.ps1
# Unit tests for Download-Video and Download-Playlist functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'content-tools.ps1')
}

Describe 'content-tools.ps1 - Download-Video' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('yt-dlp', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when yt-dlp is not available' {
            Mock-CommandAvailabilityPester -CommandName 'yt-dlp' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'yt-dlp' } -MockWith { return $null }
            
            $result = Download-Video -Url 'https://youtube.com/watch?v=test' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls yt-dlp with URL and output path' {
            Setup-AvailableCommandMock -CommandName 'yt-dlp'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'yt-dlp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '[download] video.mp4'
            }
            
            $result = Download-Video -Url 'https://youtube.com/watch?v=test' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'https://youtube.com/watch?v=test'
        }
        
        It 'Calls yt-dlp with audio-only option' {
            Setup-AvailableCommandMock -CommandName 'yt-dlp'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'yt-dlp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '[download] audio.mp3'
            }
            
            $result = Download-Video -Url 'https://youtube.com/watch?v=test' -AudioOnly -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-x'
            $script:capturedArgs | Should -Contain '--audio-format'
            $script:capturedArgs | Should -Contain 'mp3'
        }
        
        It 'Calls yt-dlp with format option' {
            Setup-AvailableCommandMock -CommandName 'yt-dlp'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'yt-dlp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '[download] video.mp4'
            }
            
            $result = Download-Video -Url 'https://youtube.com/watch?v=test' -Format 'best' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-f'
            $script:capturedArgs | Should -Contain 'best'
        }
        
        It 'Handles yt-dlp execution errors' {
            Setup-AvailableCommandMock -CommandName 'yt-dlp'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'yt-dlp' -MockWith { 
                $global:LASTEXITCODE = 1
                return 'Error: Video unavailable'
            }
            Mock Write-Error { }
            
            $result = Download-Video -Url 'https://youtube.com/watch?v=test' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'content-tools.ps1 - Download-Playlist' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('yt-dlp', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when yt-dlp is not available' {
            Mock-CommandAvailabilityPester -CommandName 'yt-dlp' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'yt-dlp' } -MockWith { return $null }
            
            $result = Download-Playlist -Url 'https://youtube.com/playlist?list=test' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls yt-dlp with playlist URL' {
            Setup-AvailableCommandMock -CommandName 'yt-dlp'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'yt-dlp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '[download] Playlist downloaded'
            }
            Mock Write-Host { }
            
            Download-Playlist -Url 'https://youtube.com/playlist?list=test' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'https://youtube.com/playlist?list=test'
        }
        
        It 'Calls yt-dlp with audio-only option for playlist' {
            Setup-AvailableCommandMock -CommandName 'yt-dlp'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'yt-dlp' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '[download] Playlist downloaded'
            }
            Mock Write-Host { }
            
            Download-Playlist -Url 'https://youtube.com/playlist?list=test' -AudioOnly -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-x'
            $script:capturedArgs | Should -Contain '--audio-format'
            $script:capturedArgs | Should -Contain 'mp3'
        }
    }
}

