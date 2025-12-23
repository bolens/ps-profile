# ===============================================
# profile-media-tools-info.tests.ps1
# Unit tests for Get-MediaInfo and Merge-MKV functions
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

Describe 'media-tools.ps1 - Get-MediaInfo' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('mediainfo', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('MediaInfo', [ref]$null)
        }
        
        # Create test file
        $script:TestMediaFile = Join-Path $TestDrive 'test-video.mp4'
        'test content' | Out-File -FilePath $script:TestMediaFile -Encoding utf8
    }
    
    Context 'Tool not available' {
        It 'Returns null when mediainfo is not available' {
            Mock-CommandAvailabilityPester -CommandName 'mediainfo' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'mediainfo' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestMediaFile } -MockWith { return $true }
            
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Media file validation' {
        It 'Returns error when media file does not exist' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.mp4' } -MockWith { return $false }
            
            { Get-MediaInfo -MediaPath 'nonexistent.mp4' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Calls mediainfo with default format' {
            Setup-AvailableCommandMock -CommandName 'mediainfo'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestMediaFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'mediainfo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return 'Media information'
            }
            
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain $script:TestMediaFile
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Calls mediainfo with JSON format' {
            Setup-AvailableCommandMock -CommandName 'mediainfo'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestMediaFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'mediainfo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '{"media": "info"}'
            }
            
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -OutputFormat 'json' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--Output=JSON'
        }
        
        It 'Calls mediainfo with XML format' {
            Setup-AvailableCommandMock -CommandName 'mediainfo'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestMediaFile } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'mediainfo' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return '<?xml version="1.0"?>'
            }
            
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -OutputFormat 'xml' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--Output=XML'
        }
        
        It 'Saves output to file when OutputPath is specified' {
            Setup-AvailableCommandMock -CommandName 'mediainfo'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestMediaFile } -MockWith { return $true }
            
            $script:outputFile = Join-Path $TestDrive 'info.json'
            Mock -CommandName 'mediainfo' -MockWith { 
                $global:LASTEXITCODE = 0
                return '{"media": "info"}'
            }
            Mock Out-File { }
            
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -OutputFormat 'json' -OutputPath $script:outputFile -ErrorAction SilentlyContinue
            
            Should -Invoke Out-File -Times 1
            $result | Should -Be $script:outputFile
        }
        
        It 'Handles mediainfo execution errors' {
            Setup-AvailableCommandMock -CommandName 'mediainfo'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestMediaFile } -MockWith { return $true }
            
            Mock -CommandName 'mediainfo' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Get-MediaInfo -MediaPath $script:TestMediaFile -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'media-tools.ps1 - Merge-MKV' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('mkvmerge', [ref]$null)
        }
        
        # Create test files
        $script:TestInputFile1 = Join-Path $TestDrive 'part1.mkv'
        $script:TestInputFile2 = Join-Path $TestDrive 'part2.mkv'
        'test content 1' | Out-File -FilePath $script:TestInputFile1 -Encoding utf8
        'test content 2' | Out-File -FilePath $script:TestInputFile2 -Encoding utf8
    }
    
    Context 'Tool not available' {
        It 'Returns null when mkvmerge is not available' {
            Mock-CommandAvailabilityPester -CommandName 'mkvmerge' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'mkvmerge' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -in @($script:TestInputFile1, $script:TestInputFile2) } -MockWith { return $true }
            
            $result = Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Input file validation' {
        It 'Returns error when input file does not exist' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.mkv' } -MockWith { return $false }
            
            { Merge-MKV -InputPaths @('nonexistent.mkv') -OutputPath 'output.mkv' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Calls mkvmerge with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'mkvmerge'
            Mock Test-Path -ParameterFilter { $LiteralPath -in @($script:TestInputFile1, $script:TestInputFile2) } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'mkvmerge' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain 'output.mkv'
            $script:capturedArgs | Should -Contain $script:TestInputFile1
            $script:capturedArgs | Should -Contain $script:TestInputFile2
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'mkvmerge'
            Mock Test-Path -ParameterFilter { $LiteralPath -in @($script:TestInputFile1, $script:TestInputFile2) } -MockWith { return $true }
            
            Mock -CommandName 'mkvmerge' -MockWith { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            $result | Should -Be 'output.mkv'
        }
        
        It 'Handles mkvmerge execution errors' {
            Setup-AvailableCommandMock -CommandName 'mkvmerge'
            Mock Test-Path -ParameterFilter { $LiteralPath -in @($script:TestInputFile1, $script:TestInputFile2) } -MockWith { return $true }
            
            Mock -CommandName 'mkvmerge' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Merge-MKV -InputPaths @($script:TestInputFile1, $script:TestInputFile2) -OutputPath 'output.mkv' -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

