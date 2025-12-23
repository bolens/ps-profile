# ===============================================
# profile-re-tools-pe.tests.ps1
# Unit tests for Analyze-PE function
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

Describe 're-tools.ps1 - Analyze-PE' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('pe-bear', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('exeinfo-pe', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('detect-it-easy', [ref]$null)
        }
    }
    
    Context 'Tool not available' {
        It 'Returns null when no PE analysis tools are available' {
            Mock-CommandAvailabilityPester -CommandName 'pe-bear' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'exeinfo-pe' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'detect-it-easy' -Available $false
            
            $result = Analyze-PE -InputFile 'test.exe' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool preference' {
        It 'Prefers pe-bear over other tools' {
            Setup-AvailableCommandMock -CommandName 'pe-bear'
            Setup-AvailableCommandMock -CommandName 'exeinfo-pe'
            Setup-AvailableCommandMock -CommandName 'detect-it-easy'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.exe' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'pe-bear' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Analysis started'
            }
            Mock -CommandName 'exeinfo-pe' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Analysis results'
            }
            Mock -CommandName 'detect-it-easy' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Analysis started'
            }
            
            $result = Analyze-PE -InputFile 'test.exe' -ErrorAction SilentlyContinue
            
            Should -Invoke 'pe-bear' -Times 1 -Exactly
            Should -Not -Invoke 'exeinfo-pe'
            Should -Not -Invoke 'detect-it-easy'
        }
        
        It 'Falls back to exeinfo-pe when pe-bear is not available' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Mock-CommandAvailabilityPester -CommandName 'pe-bear' -Available $false
            Setup-AvailableCommandMock -CommandName 'exeinfo-pe'
            
            # Verify Test-CachedCommand returns true for exeinfo-pe
            Test-CachedCommand 'exeinfo-pe' | Should -Be $true
            
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.exe' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'exeinfo-pe' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Analysis results'
            }
            
            $result = Analyze-PE -InputFile 'test.exe' -ErrorAction SilentlyContinue
            
            Should -Invoke 'exeinfo-pe' -Times 1 -Exactly
        }
        
        It 'Falls back to detect-it-easy when pe-bear and exeinfo-pe are not available' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Mock-CommandAvailabilityPester -CommandName 'pe-bear' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'exeinfo-pe' -Available $false
            Setup-AvailableCommandMock -CommandName 'detect-it-easy'
            
            # Verify Test-CachedCommand returns true for detect-it-easy
            Test-CachedCommand 'detect-it-easy' | Should -Be $true
            
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.exe' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'detect-it-easy' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Analysis started'
            }
            
            $result = Analyze-PE -InputFile 'test.exe' -ErrorAction SilentlyContinue
            
            Should -Invoke 'detect-it-easy' -Times 1 -Exactly
        }
    }
    
    Context 'Tool available' {
        It 'Calls pe-bear with input file' {
            Setup-AvailableCommandMock -CommandName 'pe-bear'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.exe' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'pe-bear' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Analysis started'
            }
            
            $result = Analyze-PE -InputFile 'test.exe' -ErrorAction SilentlyContinue
            
            # Verify pe-bear was called
            Should -Invoke 'pe-bear' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain 'test.exe'
            $result | Should -Match 'GUI tool'
        }
        
        It 'Calls exeinfo-pe with output path when specified' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            Mock-CommandAvailabilityPester -CommandName 'pe-bear' -Available $false
            Setup-AvailableCommandMock -CommandName 'exeinfo-pe'
            
            # Verify Test-CachedCommand returns true for exeinfo-pe
            Test-CachedCommand 'exeinfo-pe' | Should -Be $true
            
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.exe' } -MockWith { return $true }
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'output.txt' } -MockWith { return $true }
            
            $script:capturedArgs = @()
            Mock -CommandName 'exeinfo-pe' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Analysis results'
            }
            
            $result = Analyze-PE -InputFile 'test.exe' -OutputPath 'output.txt' -ErrorAction SilentlyContinue
            
            # Verify exeinfo-pe was called
            Should -Invoke 'exeinfo-pe' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain '-o'
            $allArgs | Should -Contain 'output.txt'
        }
        
        It 'Handles missing input file' {
            Setup-AvailableCommandMock -CommandName 'pe-bear'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'missing.exe' } -MockWith { return $false }
            
            { Analyze-PE -InputFile 'missing.exe' -ErrorAction Stop } | Should -Throw
        }
    }
}

