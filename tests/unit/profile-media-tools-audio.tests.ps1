# ===============================================
# profile-media-tools-audio.tests.ps1
# Unit tests for Tag-Audio and Rip-CD functions
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

Describe 'media-tools.ps1 - Tag-Audio' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('mp3tag', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('picard', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('tagscanner', [ref]$null)
        }
        
        # Create test file
        $script:TestAudioFile = Join-Path $TestDrive 'test-audio.mp3'
        'test content' | Out-File -FilePath $script:TestAudioFile -Encoding utf8
    }
    
    Context 'Tool not available' {
        It 'Returns null when mp3tag is not available' {
            Mock-CommandAvailabilityPester -CommandName 'mp3tag' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'mp3tag' } -MockWith { return $null }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestAudioFile } -MockWith { return $true }
            
            $result = Tag-Audio -AudioPath $script:TestAudioFile -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Path validation' {
        It 'Returns error when path does not exist' {
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.mp3' } -MockWith { return $false }
            
            { Tag-Audio -AudioPath 'nonexistent.mp3' -ErrorAction Stop } | Should -Throw
        }
    }
    
    Context 'Tool available' {
        It 'Launches mp3tag with audio file' {
            Setup-AvailableCommandMock -CommandName 'mp3tag'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestAudioFile } -MockWith { return $true }
            
            $script:capturedFilePath = $null
            $script:capturedArgs = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
                $script:capturedArgs = $ArgumentList
            }
            
            Tag-Audio -AudioPath $script:TestAudioFile -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'mp3tag'
            $script:capturedArgs | Should -Contain $script:TestAudioFile
        }
        
        It 'Launches picard when specified' {
            Setup-AvailableCommandMock -CommandName 'picard'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestAudioFile } -MockWith { return $true }
            
            $script:capturedFilePath = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
            }
            
            Tag-Audio -AudioPath $script:TestAudioFile -Tool 'picard' -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'picard'
        }
        
        It 'Launches tagscanner when specified' {
            Setup-AvailableCommandMock -CommandName 'tagscanner'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestAudioFile } -MockWith { return $true }
            
            $script:capturedFilePath = $null
            Mock Start-Process -MockWith { 
                param($FilePath, $ArgumentList)
                $script:capturedFilePath = $FilePath
            }
            
            Tag-Audio -AudioPath $script:TestAudioFile -Tool 'tagscanner' -ErrorAction SilentlyContinue
            
            $script:capturedFilePath | Should -Be 'tagscanner'
        }
        
        It 'Handles Start-Process errors' {
            Setup-AvailableCommandMock -CommandName 'mp3tag'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestAudioFile } -MockWith { return $true }
            
            Mock Start-Process -MockWith { 
                throw [System.ComponentModel.Win32Exception]::new('Access denied')
            }
            Mock Write-Error { }
            
            Tag-Audio -AudioPath $script:TestAudioFile -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

Describe 'media-tools.ps1 - Rip-CD' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('cyanrip', [ref]$null)
        }
        
        # Create test directory
        $script:TestOutputDir = Join-Path $TestDrive 'ripped'
    }
    
    Context 'Tool not available' {
        It 'Returns null when cyanrip is not available' {
            Mock-CommandAvailabilityPester -CommandName 'cyanrip' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'cyanrip' } -MockWith { return $null }
            
            $result = Rip-CD -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls cyanrip with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'cyanrip'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestOutputDir } -MockWith { return $false }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $script:TestOutputDir } }
            
            $script:capturedArgs = $null
            Mock -CommandName 'cyanrip' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Rip-CD -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-o'
            $script:capturedArgs | Should -Contain $script:TestOutputDir
            $script:capturedArgs | Should -Contain '-f'
            $script:capturedArgs | Should -Contain 'flac'
        }
        
        It 'Calls cyanrip with custom format' {
            Setup-AvailableCommandMock -CommandName 'cyanrip'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestOutputDir } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'cyanrip' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Rip-CD -OutputPath $script:TestOutputDir -Format 'mp3' -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-f'
            $script:capturedArgs | Should -Contain 'mp3'
        }
        
        It 'Calls cyanrip with quality setting' {
            Setup-AvailableCommandMock -CommandName 'cyanrip'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestOutputDir } -MockWith { return $true }
            
            $script:capturedArgs = $null
            Mock -CommandName 'cyanrip' -MockWith { 
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Rip-CD -OutputPath $script:TestOutputDir -Format 'mp3' -Quality 2 -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-q'
            $script:capturedArgs | Should -Contain '2'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'cyanrip'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestOutputDir } -MockWith { return $true }
            
            Mock -CommandName 'cyanrip' -MockWith { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Rip-CD -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue
            
            $result | Should -Be $script:TestOutputDir
        }
        
        It 'Handles cyanrip execution errors' {
            Setup-AvailableCommandMock -CommandName 'cyanrip'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq $script:TestOutputDir } -MockWith { return $true }
            
            Mock -CommandName 'cyanrip' -MockWith { 
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-Error { }
            
            $result = Rip-CD -OutputPath $script:TestOutputDir -ErrorAction SilentlyContinue
            
            Should -Invoke Write-Error -Times 1
        }
    }
}

