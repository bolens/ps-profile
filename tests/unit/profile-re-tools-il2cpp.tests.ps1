# ===============================================
# profile-re-tools-il2cpp.tests.ps1
# Unit tests for Dump-IL2CPP function
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

Describe 're-tools.ps1 - Dump-IL2CPP' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('il2cppdumper', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when il2cppdumper is not available' {
            Mock-CommandAvailabilityPester -CommandName 'il2cppdumper' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'il2cppdumper' } -MockWith { return $null }
            
            $result = Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'GameAssembly.dll' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls il2cppdumper with metadata and binary files' {
            Setup-AvailableCommandMock -CommandName 'il2cppdumper'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'metadata.dat' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'GameAssembly.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'il2cppdumper' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Dump complete'
            }
            
            $result = Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'GameAssembly.dll' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            # Verify il2cppdumper was called
            Should -Invoke 'il2cppdumper' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain 'GameAssembly.dll'
            $allArgs | Should -Contain 'metadata.dat'
            $allArgs | Should -Contain $TestDrive
        }
        
        It 'Calls il2cppdumper with Unity version when specified' {
            Setup-AvailableCommandMock -CommandName 'il2cppdumper'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'metadata.dat' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'GameAssembly.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'il2cppdumper' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Dump complete'
            }
            
            $result = Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'GameAssembly.dll' -UnityVersion '2021.3.0' -ErrorAction SilentlyContinue
            
            # Verify il2cppdumper was called
            Should -Invoke 'il2cppdumper' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain '-v'
            $allArgs | Should -Contain '2021.3.0'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'il2cppdumper'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'metadata.dat' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'GameAssembly.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'il2cppdumper' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Dump complete'
            }
            
            $result = Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'GameAssembly.dll' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            $result | Should -Be $TestDrive
        }
        
        It 'Handles missing metadata file' {
            Setup-AvailableCommandMock -CommandName 'il2cppdumper'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'missing.dat' } -MockWith { return $false }
            
            { Dump-IL2CPP -MetadataFile 'missing.dat' -BinaryFile 'GameAssembly.dll' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Handles missing binary file' {
            Setup-AvailableCommandMock -CommandName 'il2cppdumper'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'metadata.dat' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'missing.dll' } -MockWith { return $false }
            
            { Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'missing.dll' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Handles command failure' {
            Setup-AvailableCommandMock -CommandName 'il2cppdumper'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'metadata.dat' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'GameAssembly.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'il2cppdumper' -MockWith { 
                $global:LASTEXITCODE = 1
                return 'Error: Failed to dump'
            }
            
            { Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'GameAssembly.dll' -ErrorAction Stop } | Should -Throw
        }
    }
}

