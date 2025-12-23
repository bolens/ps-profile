# ===============================================
# profile-re-tools-java.tests.ps1
# Unit tests for Decompile-Java function
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 're-tools.ps1')
}

Describe 're-tools.ps1 - Decompile-Java' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('jadx', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when jadx is not available' {
            Mock-CommandAvailabilityPester -CommandName 'jadx' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'jadx' } -MockWith { return $null }
            
            $result = Decompile-Java -InputFile 'test.dex' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls jadx with input file and output path' {
            Setup-AvailableCommandMock -CommandName 'jadx'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.dex' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'jadx' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            
            $result = Decompile-Java -InputFile 'test.dex' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            # Verify jadx was called
            Should -Invoke 'jadx' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            # The mock captures all arguments, so we need to flatten if nested
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain '-d'
            $allArgs | Should -Contain $TestDrive
            $allArgs | Should -Contain 'test.dex'
        }
        
        It 'Calls jadx with DecompileResources flag' {
            Setup-AvailableCommandMock -CommandName 'jadx'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'jadx' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            
            $result = Decompile-Java -InputFile 'test.apk' -DecompileResources -ErrorAction SilentlyContinue
            
            # Verify jadx was called
            Should -Invoke 'jadx' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain '--no-res'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'jadx'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.dex' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'jadx' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            
            $result = Decompile-Java -InputFile 'test.dex' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            $result | Should -Be $TestDrive
        }
        
        It 'Handles missing input file' {
            Setup-AvailableCommandMock -CommandName 'jadx'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'missing.dex' } -MockWith { return $false }
            
            { Decompile-Java -InputFile 'missing.dex' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Handles command failure' {
            Setup-AvailableCommandMock -CommandName 'jadx'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.dex' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'jadx' -MockWith { 
                $global:LASTEXITCODE = 1
                return 'Error: Failed to decompile'
            }
            
            { Decompile-Java -InputFile 'test.dex' -ErrorAction Stop } | Should -Throw
        }
    }
}

