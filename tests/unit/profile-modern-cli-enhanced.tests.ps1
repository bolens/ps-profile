# ===============================================
# profile-modern-cli-enhanced.tests.ps1
# Unit tests for enhanced modern-cli functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'modern-cli.ps1')
}

Describe 'modern-cli.ps1 - Enhanced Functions' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('fd', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('rg', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('zoxide', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('bat', [ref]$null)
        }
        
        # Mock Get-Location to return TestDrive
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Find-WithFd' {
        It 'Returns empty array when fd is not available' {
            Mock-CommandAvailabilityPester -CommandName 'fd' -Available $false
            
            $result = Find-WithFd -Pattern "test" -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Calls fd with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'fd'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'fd') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return @('file1.txt', 'file2.txt')
                }
            }
            
            $result = Find-WithFd -Pattern "test" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--ignore-case'
            $script:capturedArgs | Should -Contain 'test'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Adds type filter when specified' {
            Setup-AvailableCommandMock -CommandName 'fd'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'fd') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return @('file1.txt')
                }
            }
            
            Find-WithFd -Pattern "test" -Type f -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--type'
            $script:capturedArgs | Should -Contain 'f'
        }
        
        It 'Adds extension filter when specified' {
            Setup-AvailableCommandMock -CommandName 'fd'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'fd') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return @('file1.ps1')
                }
            }
            
            Find-WithFd -Pattern "test" -Extension "ps1" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--extension'
            $script:capturedArgs | Should -Contain 'ps1'
        }
        
        It 'Adds hidden flag when specified' {
            Setup-AvailableCommandMock -CommandName 'fd'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'fd') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return @()
                }
            }
            
            Find-WithFd -Pattern "test" -Hidden -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--hidden'
        }
        
        It 'Handles case-sensitive search' {
            Setup-AvailableCommandMock -CommandName 'fd'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'fd') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return @()
                }
            }
            
            Find-WithFd -Pattern "Test" -CaseSensitive -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Not -Contain '--ignore-case'
        }
    }
    
    Context 'Grep-WithRipgrep' {
        It 'Returns empty string when rg is not available' {
            Mock-CommandAvailabilityPester -CommandName 'rg' -Available $false
            
            $result = Grep-WithRipgrep -Pattern "test" -ErrorAction SilentlyContinue
            
            $result | Should -Be ""
        }
        
        It 'Calls rg with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'rg'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'rg') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "match found"
                }
            }
            
            $result = Grep-WithRipgrep -Pattern "test" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--ignore-case'
            $script:capturedArgs | Should -Contain '--line-number'
            $script:capturedArgs | Should -Contain 'test'
            $result | Should -Be "match found"
        }
        
        It 'Adds context lines when specified' {
            Setup-AvailableCommandMock -CommandName 'rg'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'rg') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "match with context"
                }
            }
            
            Grep-WithRipgrep -Pattern "test" -Context 3 -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-C'
            $script:capturedArgs | Should -Contain '3'
        }
        
        It 'Adds file type filter when specified' {
            Setup-AvailableCommandMock -CommandName 'rg'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'rg') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "match"
                }
            }
            
            Grep-WithRipgrep -Pattern "test" -FileType "ps1" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-t'
            $script:capturedArgs | Should -Contain 'ps1'
        }
        
        It 'Handles exit code 1 (no matches) as valid' {
            Setup-AvailableCommandMock -CommandName 'rg'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'rg') {
                    $global:LASTEXITCODE = 1
                    return ""
                }
            }
            
            $result = Grep-WithRipgrep -Pattern "nonexistent" -ErrorAction SilentlyContinue
            
            $result | Should -Be ""
        }
        
        It 'Adds files-with-matches flag when specified' {
            Setup-AvailableCommandMock -CommandName 'rg'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'rg') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return "file1.ps1"
                }
            }
            
            Grep-WithRipgrep -Pattern "test" -FilesWithMatches -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '-l'
        }
    }
    
    Context 'Navigate-WithZoxide' {
        It 'Returns null when zoxide is not available' {
            Mock-CommandAvailabilityPester -CommandName 'zoxide' -Available $false
            
            $result = Navigate-WithZoxide -Query "test" -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Adds current directory to zoxide database' {
            Setup-AvailableCommandMock -CommandName 'zoxide'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'zoxide' -and $args[0] -eq 'add') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            $result = Navigate-WithZoxide -Add -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'add'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Queries zoxide for directory' {
            Setup-AvailableCommandMock -CommandName 'zoxide'
            $script:capturedArgs = $null
            $script:mockPath = Join-Path $TestDrive 'Documents'
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'zoxide' -and $args[0] -eq 'query') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return $script:mockPath
                }
            }
            Mock Set-Location -MockWith { return }
            
            $result = Navigate-WithZoxide -Query "Documents" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain 'query'
            $script:capturedArgs | Should -Contain 'Documents'
            $result | Should -Be $script:mockPath
        }
        
        It 'Adds interactive flag when specified' {
            Setup-AvailableCommandMock -CommandName 'zoxide'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'zoxide' -and $args[0] -eq 'query') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return $TestDrive
                }
            }
            Mock Set-Location -MockWith { return }
            
            Navigate-WithZoxide -Query "test" -Interactive -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--interactive'
        }
        
        It 'Queries all directories when QueryAll specified' {
            Setup-AvailableCommandMock -CommandName 'zoxide'
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'zoxide' -and $args[0] -eq 'query' -and $args[1] -eq '--all') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                    return @('path1', 'path2')
                }
            }
            
            $result = Navigate-WithZoxide -QueryAll -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--all'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Warns when no query specified' {
            Setup-AvailableCommandMock -CommandName 'zoxide'
            
            $result = Navigate-WithZoxide -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'View-WithBat' {
        It 'Returns when bat is not available' {
            Mock-CommandAvailabilityPester -CommandName 'bat' -Available $false
            
            View-WithBat -Path "test.txt" -ErrorAction SilentlyContinue
            
            # Should complete without error
        }
        
        It 'Calls bat with correct arguments' {
            Setup-AvailableCommandMock -CommandName 'bat'
            $testFile = Join-Path $TestDrive 'test.txt'
            'test content' | Out-File -FilePath $testFile
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'bat') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            View-WithBat -Path $testFile -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--paging=never'
            $script:capturedArgs | Should -Contain '--wrap=never'
            $script:capturedArgs | Should -Contain $testFile
        }
        
        It 'Adds language when specified' {
            Setup-AvailableCommandMock -CommandName 'bat'
            $testFile = Join-Path $TestDrive 'test.ps1'
            'function test {}' | Out-File -FilePath $testFile
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'bat') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            View-WithBat -Path $testFile -Language "powershell" -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--language'
            $script:capturedArgs | Should -Contain 'powershell'
        }
        
        It 'Disables line numbers when specified' {
            Setup-AvailableCommandMock -CommandName 'bat'
            $testFile = Join-Path $TestDrive 'test.txt'
            'content' | Out-File -FilePath $testFile
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'bat') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            View-WithBat -Path $testFile -LineNumbers:$false -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--no-line-numbers'
        }
        
        It 'Adds plain flag when specified' {
            Setup-AvailableCommandMock -CommandName 'bat'
            $testFile = Join-Path $TestDrive 'test.txt'
            'content' | Out-File -FilePath $testFile
            $script:capturedArgs = $null
            Mock & {
                param($cmd, $args)
                if ($cmd -eq 'bat') {
                    $script:capturedArgs = $args
                    $global:LASTEXITCODE = 0
                }
            }
            
            View-WithBat -Path $testFile -Plain -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Contain '--plain'
        }
        
        It 'Warns when file does not exist' {
            Setup-AvailableCommandMock -CommandName 'bat'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'nonexistent.txt' } -MockWith { return $false }
            
            View-WithBat -Path "nonexistent.txt" -ErrorAction SilentlyContinue
            
            # Should complete without error (warning handled internally)
        }
    }
}
