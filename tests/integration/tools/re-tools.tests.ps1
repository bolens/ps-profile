# ===============================================
# re-tools.tests.ps1
# Integration tests for re-tools.ps1 module
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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
        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }
        }

        BeforeAll {
            . (Join-Path $script:ProfileDir 're-tools.ps1')
        }

        It 'Decompile-Java handles missing jadx gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'jadx' -Available $false

            $output = & { Decompile-Java -InputFile 'test.dex' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'jadx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'jadx'
        }

        It 'Decompile-DotNet handles missing tools gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'dnspyex' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'dnspy' -Available $false

            $output = & { Decompile-DotNet -InputFile 'test.dll' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'dnspyex not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'dnspyex'
        }

        It 'Analyze-PE handles missing tools gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'pe-bear' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'exeinfo-pe' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'detect-it-easy' -Available $false

            $output = & { Analyze-PE -InputFile 'test.exe' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pe-bear not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'pe-bear'
        }

        It 'Extract-AndroidApk handles missing apktool gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'apktool' -Available $false

            $output = & { Extract-AndroidApk -InputFile 'test.apk' -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'apktool not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'apktool'
        }

        It 'Dump-IL2CPP handles missing il2cppdumper gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'il2cppdumper' -Available $false

            $output = & {
                Dump-IL2CPP -MetadataFile 'metadata.dat' -BinaryFile 'GameAssembly.dll' -ErrorAction SilentlyContinue
            } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'il2cppdumper not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'il2cppdumper'
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
            
            Decompile-Java -InputFile 'test.dex' -OutputPath $TestDrive -ErrorAction Stop
            Should -Invoke -CommandName 'jadx' -Times 1 -Exactly
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
            
            Decompile-DotNet -InputFile 'test.dll' -OutputPath $TestDrive -ErrorAction Stop
            Should -Invoke -CommandName 'dnspyex' -Times 1 -Exactly
        }
    }
}

