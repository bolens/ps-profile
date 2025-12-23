# ===============================================
# profile-re-tools-dotnet.tests.ps1
# Unit tests for Decompile-DotNet function
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

Describe 're-tools.ps1 - Decompile-DotNet' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('dnspyex', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('dnspy', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when neither dnspyex nor dnspy is available' {
            Mock-CommandAvailabilityPester -CommandName 'dnspyex' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dnspy' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'dnspyex' -or $Name -eq 'dnspy' } -MockWith { return $null }
            
            $result = Decompile-DotNet -InputFile 'test.dll' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool preference' {
        It 'Prefers dnspyex over dnspy when both are available' {
            Setup-AvailableCommandMock -CommandName 'dnspyex'
            Setup-AvailableCommandMock -CommandName 'dnspy'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.cs' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'dnspyex' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            Mock -CommandName 'dnspy' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            
            $result = Decompile-DotNet -InputFile 'test.dll' -ErrorAction SilentlyContinue
            
            Should -Invoke 'dnspyex' -Times 1 -Exactly
            Should -Not -Invoke 'dnspy'
        }
        
        It 'Falls back to dnspy when dnspyex is not available' {
            Mock-CommandAvailabilityPester -CommandName 'dnspyex' -Available $false
            Setup-AvailableCommandMock -CommandName 'dnspy'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.cs' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'dnspy' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            
            $result = Decompile-DotNet -InputFile 'test.dll' -ErrorAction SilentlyContinue
            
            Should -Invoke 'dnspy' -Times 1 -Exactly
        }
    }
    
    Context 'Tool available' {
        It 'Calls tool with input file and output path' {
            Setup-AvailableCommandMock -CommandName 'dnspyex'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.cs' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'dnspyex' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            
            $result = Decompile-DotNet -InputFile 'test.dll' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            # Verify dnspyex was called
            Should -Invoke 'dnspyex' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & $tool $arguments, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain '-o'
            $allArgs | Should -Contain 'test.dll'
        }
        
        It 'Uses IL format when specified' {
            Setup-AvailableCommandMock -CommandName 'dnspyex'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.dll' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            Mock Test-Path -ParameterFilter { $LiteralPath -like '*.il' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'dnspyex' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Decompilation complete'
            }
            
            $result = Decompile-DotNet -InputFile 'test.dll' -OutputFormat 'il' -ErrorAction SilentlyContinue
            
            $result | Should -Match '\.il$'
        }
        
        It 'Handles missing input file' {
            Setup-AvailableCommandMock -CommandName 'dnspyex'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'missing.dll' } -MockWith { return $false }
            
            { Decompile-DotNet -InputFile 'missing.dll' -ErrorAction Stop } | Should -Throw
        }
    }
}

