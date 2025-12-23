# ===============================================
# profile-content-tools-gallery.tests.ps1
# Unit tests for Download-Gallery, Archive-WebPage, and Download-Twitch functions
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

Describe 'content-tools.ps1 - Download-Gallery' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('gallery-dl', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when gallery-dl is not available' {
            Mock-CommandAvailabilityPester -CommandName 'gallery-dl' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'gallery-dl' } -MockWith { return $null }
            
            $result = Download-Gallery -Url 'https://example.com/gallery' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls gallery-dl with URL and output path' {
            Setup-AvailableCommandMock -CommandName 'gallery-dl'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'gallery-dl' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Downloaded gallery'
            }
            Mock Write-Host { }
            
            Download-Gallery -Url 'https://example.com/gallery' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-D'
            $script:capturedArgs | Should -Contain $TestDrive
            $script:capturedArgs | Should -Contain 'https://example.com/gallery'
        }
        
        It 'Handles gallery-dl execution errors' {
            Setup-AvailableCommandMock -CommandName 'gallery-dl'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'gallery-dl' -MockWith { 
                $global:LASTEXITCODE = 1
                return 'Error: Gallery not found'
            }
            Mock Write-Error { }
            
            $result = Download-Gallery -Url 'https://example.com/gallery' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'content-tools.ps1 - Archive-WebPage' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('monolith', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when monolith is not available' {
            Mock-CommandAvailabilityPester -CommandName 'monolith' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'monolith' } -MockWith { return $null }
            
            $result = Archive-WebPage -Url 'https://example.com/page' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls monolith with URL and output file' {
            Setup-AvailableCommandMock -CommandName 'monolith'
            
            $script:capturedArgs = @()
            Mock -CommandName 'monolith' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                # monolith is called as: & monolith $Url -o $OutputFile
                # Arguments will be: $Url, '-o', $OutputFile
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $outputFile = Join-Path $TestDrive 'archived.html'
            $result = Archive-WebPage -Url 'https://example.com/page' -OutputFile $outputFile -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'https://example.com/page'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain $outputFile
            $result | Should -Be $outputFile
        }
        
        It 'Uses default output file when not specified' {
            Setup-AvailableCommandMock -CommandName 'monolith'
            Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'monolith' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Archive-WebPage -Url 'https://example.com/page' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'https://example.com/page'
            $script:capturedArgs | Should -Contain '-o'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles monolith execution errors' {
            Setup-AvailableCommandMock -CommandName 'monolith'
            
            Mock -CommandName 'monolith' -MockWith { 
                $global:LASTEXITCODE = 1
                return 'Error: Failed to archive'
            }
            Mock Write-Error { }
            
            $result = Archive-WebPage -Url 'https://example.com/page' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'content-tools.ps1 - Download-Twitch' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('twitchdownloader-cli', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('twitchdownloader', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when neither twitchdownloader nor twitchdownloader-cli is available' {
            Mock-CommandAvailabilityPester -CommandName 'twitchdownloader-cli' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'twitchdownloader' -Available $false
            Mock Get-Command -ParameterFilter { $Name -in @('twitchdownloader-cli', 'twitchdownloader') } -MockWith { return $null }
            
            $result = Download-Twitch -Url 'https://twitch.tv/videos/123' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'twitchdownloader-cli available' {
        It 'Calls twitchdownloader-cli with URL' {
            Setup-AvailableCommandMock -CommandName 'twitchdownloader-cli'
            Mock-CommandAvailabilityPester -CommandName 'twitchdownloader' -Available $false
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'twitchdownloader-cli' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Downloaded'
            }
            Mock Write-Host { }
            
            Download-Twitch -Url 'https://twitch.tv/videos/123' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-u'
            $script:capturedArgs | Should -Contain 'https://twitch.tv/videos/123'
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain $TestDrive
        }
        
        It 'Calls twitchdownloader-cli with quality option' {
            Setup-AvailableCommandMock -CommandName 'twitchdownloader-cli'
            Mock-CommandAvailabilityPester -CommandName 'twitchdownloader' -Available $false
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'twitchdownloader-cli' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Downloaded'
            }
            Mock Write-Host { }
            
            Download-Twitch -Url 'https://twitch.tv/videos/123' -Quality '1080p' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-q'
            $script:capturedArgs | Should -Contain '1080p'
        }
    }
    
    Context 'twitchdownloader fallback' {
        It 'Calls twitchdownloader when twitchdownloader-cli not available' {
            Mock-CommandAvailabilityPester -CommandName 'twitchdownloader-cli' -Available $false
            Setup-AvailableCommandMock -CommandName 'twitchdownloader'
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'twitchdownloader' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Downloaded'
            }
            Mock Write-Host { }
            
            Download-Twitch -Url 'https://twitch.tv/videos/123' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-u'
            $script:capturedArgs | Should -Contain 'https://twitch.tv/videos/123'
        }
    }
}

