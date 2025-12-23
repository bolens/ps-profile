# ===============================================
# profile-re-tools-android.tests.ps1
# Unit tests for Extract-AndroidApk function
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

Describe 're-tools.ps1 - Extract-AndroidApk' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        
        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('apktool', [ref]$null)
        }
        
        Mock Get-Location -MockWith { return [PSCustomObject]@{ Path = $TestDrive } }
    }
    
    Context 'Tool not available' {
        It 'Returns null when apktool is not available' {
            Mock-CommandAvailabilityPester -CommandName 'apktool' -Available $false
            Mock Get-Command -ParameterFilter { $Name -eq 'apktool' } -MockWith { return $null }
            
            $result = Extract-AndroidApk -InputFile 'test.apk' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Tool available' {
        It 'Calls apktool with input file and output path' {
            Setup-AvailableCommandMock -CommandName 'apktool'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'apktool' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Extraction complete'
            }
            
            $result = Extract-AndroidApk -InputFile 'test.apk' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            # Verify apktool was called
            Should -Invoke 'apktool' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain 'd'
            $allArgs | Should -Contain '-o'
            $allArgs | Should -Contain 'test.apk'
        }
        
        It 'Calls apktool with Decompile flag' {
            Setup-AvailableCommandMock -CommandName 'apktool'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'apktool' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Extraction complete'
            }
            
            $result = Extract-AndroidApk -InputFile 'test.apk' -Decompile -ErrorAction SilentlyContinue
            
            $script:capturedArgs | Should -Not -Contain '--no-src'
        }
        
        It 'Calls apktool with NoResources flag' {
            Setup-AvailableCommandMock -CommandName 'apktool'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            $script:capturedArgs = @()
            Mock -CommandName 'apktool' -MockWith { 
                $script:capturedArgs = $args
                $global:LASTEXITCODE = 0
                return 'Extraction complete'
            }
            
            $result = Extract-AndroidApk -InputFile 'test.apk' -NoResources -ErrorAction SilentlyContinue
            
            # Verify apktool was called
            Should -Invoke 'apktool' -Times 1 -Exactly
            $script:capturedArgs | Should -Not -BeNullOrEmpty
            # When using & command $array, PowerShell splats the array
            $allArgs = $script:capturedArgs | ForEach-Object { if ($_ -is [System.Array]) { $_ } else { $_ } } | ForEach-Object { $_ }
            $allArgs | Should -Contain '--no-res'
            $allArgs | Should -Contain '--no-src'
        }
        
        It 'Returns output path on success' {
            Setup-AvailableCommandMock -CommandName 'apktool'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'apktool' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Extraction complete'
            }
            
            $result = Extract-AndroidApk -InputFile 'test.apk' -OutputPath $TestDrive -ErrorAction SilentlyContinue
            
            $result | Should -Match 'test$'
        }
        
        It 'Handles missing input file' {
            Setup-AvailableCommandMock -CommandName 'apktool'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'missing.apk' } -MockWith { return $false }
            
            { Extract-AndroidApk -InputFile 'missing.apk' -ErrorAction Stop } | Should -Throw
        }
        
        It 'Handles command failure' {
            Setup-AvailableCommandMock -CommandName 'apktool'
            Mock Test-Path -ParameterFilter { $LiteralPath -eq 'test.apk' } -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            
            Mock -CommandName 'apktool' -MockWith { 
                $global:LASTEXITCODE = 1
                return 'Error: Failed to extract'
            }
            
            { Extract-AndroidApk -InputFile 'test.apk' -ErrorAction Stop } | Should -Throw
        }
    }
}

