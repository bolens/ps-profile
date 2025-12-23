# ===============================================
# profile-media-tools-video.tests.ps1
# Unit tests for Convert-Video and Extract-Audio functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'media-tools.ps1')
}

Describe 'media-tools.ps1 - Convert-Video' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('ffmpeg', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('handbrake-cli', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('HandBrakeCLI', [ref]$null)
        }
        
        # Create test file
        $script:TestInputFile = Join-Path $TestDrive 'test-input.mp4'
        'test content' | Out-File -FilePath $script:TestInputFile -Encoding utf8
    }
    
    Context 'Tool not available' {
        It 'Returns null when ffmpeg is not available' {
            Mock-CommandAvailabilityPester -CommandName 'ffmpeg' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'ffmpeg' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Returns null when handbrake is not available' {
            Mock-CommandAvailabilityPester -CommandName 'handbrake-cli' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'handbrake-cli' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -UseHandbrake -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Input file validation' {
        It 'Returns error when input file does not exist' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.mp4' } -MockWith { return $false }
            
            { Convert-Video -InputPath 'nonexistent.mp4' -OutputPath 'output.mkv' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'FFmpeg conversion' {
        It 'Calls ffmpeg with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'ffmpeg' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-i'
            $script:capturedArgs | Should -Contain $script:TestInputFile
            $script:capturedArgs | Should -Contain 'output.mkv'
        }
        
        It 'Calls ffmpeg with custom codec and quality' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'ffmpeg' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -Codec 'hevc' -Quality 20 -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-c:v'
            $script:capturedArgs | Should -Contain 'hevc'
            $script:capturedArgs | Should -Contain '-crf'
            $script:capturedArgs | Should -Contain '20'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            Mock -CommandName 'ffmpeg' -MockWith { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'output.mkv'
        }
        
        It 'Handles ffmpeg execution errors' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            Mock -CommandName 'ffmpeg' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
    
    Context 'Handbrake conversion' {
        It 'Calls handbrake-cli with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'handbrake-cli'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'handbrake-cli' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -UseHandbrake -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-i'
            $script:capturedArgs | Should -Contain $script:TestInputFile
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'output.mkv'
        }
        
        It 'Calls handbrake-cli with preset' {
            Setup-AvailableCommandMock -CommandName 'handbrake-cli'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'handbrake-cli' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Convert-Video -InputPath $script:TestInputFile -OutputPath 'output.mkv' -UseHandbrake -Preset 'Fast 1080p30' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--preset'
            $script:capturedArgs | Should -Contain 'Fast 1080p30'
        }
    }
}

Describe 'media-tools.ps1 - Extract-Audio' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('ffmpeg', [ref]$null)
        }
        
        # Create test file
        $script:TestInputFile = Join-Path $TestDrive 'test-video.mp4'
        'test content' | Out-File -FilePath $script:TestInputFile -Encoding utf8
    }
    
    Context 'Tool not available' {
        It 'Returns null when ffmpeg is not available' {
            Mock-CommandAvailabilityPester -CommandName 'ffmpeg' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'ffmpeg' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $result = Extract-Audio -InputPath $script:TestInputFile -OutputPath 'audio.mp3' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Input file validation' {
        It 'Returns error when input file does not exist' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.mp4' } -MockWith { return $false }
            
            { Extract-Audio -InputPath 'nonexistent.mp4' -OutputPath 'audio.mp3' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Calls ffmpeg with correct arguments for MP3 extraction' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'ffmpeg' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Extract-Audio -InputPath $script:TestInputFile -OutputPath 'audio.mp3' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-i'
            $script:capturedArgs | Should -Contain $script:TestInputFile
            $script:capturedArgs | Should -Contain '-vn'
            $script:capturedArgs | Should -Contain '-acodec'
            $script:capturedArgs | Should -Contain 'mp3'
            $script:capturedArgs | Should -Contain 'audio.mp3'
        }
        
        It 'Calls ffmpeg with FLAC codec' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'ffmpeg' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Extract-Audio -InputPath $script:TestInputFile -OutputPath 'audio.flac' -AudioCodec 'flac' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-acodec'
            $script:capturedArgs | Should -Contain 'flac'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            Mock -CommandName 'ffmpeg' -MockWith { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Extract-Audio -InputPath $script:TestInputFile -OutputPath 'audio.mp3' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'audio.mp3'
        }
        
        It 'Handles ffmpeg execution errors' {
            Setup-AvailableCommandMock -CommandName 'ffmpeg'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestInputFile } -MockWith { return $true }
            
            Mock -CommandName 'ffmpeg' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Extract-Audio -InputPath $script:TestInputFile -OutputPath 'audio.mp3' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

