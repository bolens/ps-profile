# ===============================================
# re-tools.tests.ps1
# Integration tests for re-tools.ps1 module
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 're-tools.ps1 - Integration Tests' {
    Context 'Module Loading' {
        It 'Loads fragment without errors' {
            { . (Join-Path $script:ProfileDir 're-tools.ps1') } | Should -Not -Throw
        }
        
        It 'Is idempotent (can be loaded multiple times)' {
            { 
                . (Join-Path $script:ProfileDir 're-tools.ps1')
                . (Join-Path $script:ProfileDir 're-tools.ps1')
            } | Should -Not -Throw
        }
    }
    
    Context 'Function Registration' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 're-tools.ps1')
        }
        
        It 'Registers Decompile-Java function' {
            Get-Command -Name 'Decompile-Java' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Decompile-DotNet function' {
            Get-Command -Name 'Decompile-DotNet' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Analyze-PE function' {
            Get-Command -Name 'Analyze-PE' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Extract-AndroidApk function' {
            Get-Command -Name 'Extract-AndroidApk' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Registers Dump-IL2CPP function' {
            Get-Command -Name 'Dump-IL2CPP' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Graceful Degradation' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 're-tools.ps1')
        }
        
        It 'Decompile-Java handles missing jadx gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'jadx' -Available $false
            
            $result = Decompile-Java -InputFile 'test.dex' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Decompile-DotNet handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'dnspyex' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dnspy' -Available $false
            
            $result = Decompile-DotNet -InputFile 'test.dll' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Analyze-PE handles missing tools gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'pe-bear' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'exeinfo-pe' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'detect-it-easy' -Available $false
            
            $result = Analyze-PE -InputFile 'test.exe' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Extract-AndroidApk handles missing apktool gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'apktool' -Available $false
            
            $result = Extract-AndroidApk -InputFile 'test.apk' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Dump-IL2CPP handles missing il2cppdumper gracefully' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Mock-CommandAvailabilityPester -CommandName 'il2cppdumper' -Available $false
            
            $result = Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'GameAssembly.dll' -ErrorAction SilentlyContinue
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context 'Function Execution' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 're-tools.ps1')
        }
        
        It 'Decompile-Java accepts parameters' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Setup-AvailableCommandMock -CommandName 'jadx'
            Mock Test-Path -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            Mock -CommandName 'jadx' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Success'
            }
            
            { Decompile-Java -InputFile 'test.dex' -OutputPath $TestDrive -ErrorAction Stop } | Should -Not -Throw
        }
        
        It 'Decompile-DotNet accepts parameters' {
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
            
            Setup-AvailableCommandMock -CommandName 'dnspyex'
            Mock Test-Path -MockWith { return $true }
            Mock New-Item -MockWith { return [PSCustomObject]@{ FullName = $TestDrive } }
            Mock -CommandName 'dnspyex' -MockWith { 
                $global:LASTEXITCODE = 0
                return 'Success'
            }
            
            { Decompile-DotNet -InputFile 'test.dll' -OutputPath $TestDrive -ErrorAction Stop } | Should -Not -Throw
        }
    }
}

