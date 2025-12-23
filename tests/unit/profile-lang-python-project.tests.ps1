# ===============================================
# profile-lang-python-project.tests.ps1
# Unit tests for New-PythonProject and Install-PythonPackage functions
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

# Import mocking utilities
$mockingDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestSupport' 'Mocking'
Import-Module (Join-Path $mockingDir 'PesterMocks.psm1') -DisableNameChecking -ErrorAction SilentlyContinue

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-python.ps1')
}

Describe 'lang-python.ps1 - New-PythonProject' {
    BeforeEach {
        $script:TestDrive = $TestDrive
    }

    Context 'Project creation' {
        It 'Creates project directory structure' {
            $projectPath = New-PythonProject -Name 'testproject' -Path $script:TestDrive

            $projectPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $projectPath | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'README.md') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath '.gitignore') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'main.py') | Should -Be $true
        }

        It 'Creates requirements.txt when uv is not available' {
            Mock-CommandAvailabilityPester -CommandName 'uv' -Available $false

            $projectPath = New-PythonProject -Name 'testproject2' -Path $script:TestDrive

            Test-Path -LiteralPath (Join-Path $projectPath 'requirements.txt') | Should -Be $true
        }

        It 'Uses uv init when UseUV is specified and uv is available' {
            Setup-AvailableCommandMock -CommandName 'uv'

            $script:capturedArgs = $null
            Mock -CommandName 'uv' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Project initialized' 
            }

            $projectPath = New-PythonProject -Name 'testproject3' -Path $script:TestDrive -UseUV

            $projectPath | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'init'
        }

        It 'Does not overwrite existing files' {
            $projectPath = New-PythonProject -Name 'testproject4' -Path $script:TestDrive
            $readmePath = Join-Path $projectPath 'README.md'
            Set-Content -Path $readmePath -Value 'Custom README'

            # Create again - should not overwrite
            $projectPath2 = New-PythonProject -Name 'testproject4' -Path $script:TestDrive

            Get-Content -Path $readmePath | Should -Contain 'Custom README'
        }
    }
}

Describe 'lang-python.ps1 - Install-PythonPackage' {
    BeforeEach {
        # Clear command cache
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Variable -Name 'TestCachedCommandCache' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:TestCachedCommandCache.TryRemove('uv', [ref]$null)
            $null = $global:TestCachedCommandCache.TryRemove('pip', [ref]$null)
        }

        if (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue) {
            $null = $global:AssumedAvailableCommands.TryRemove('uv', [ref]$null)
            $null = $global:AssumedAvailableCommands.TryRemove('pip', [ref]$null)
        }
    }

    Context 'Tool not available' {
        It 'Returns null when neither uv nor pip is available' {
            Mock-CommandAvailabilityPester -CommandName 'uv' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'pip' -Available $false

            $result = Install-PythonPackage -Packages @('requests') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Prefers uv when available' {
            Setup-AvailableCommandMock -CommandName 'uv'

            $script:capturedArgs = $null
            Mock -CommandName 'uv' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed requests' 
            }

            $result = Install-PythonPackage -Packages @('requests')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'pip'
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain 'requests'
        }

        It 'Falls back to pip when uv is not available' {
            Mock-CommandAvailabilityPester -CommandName 'uv' -Available $false
            Setup-AvailableCommandMock -CommandName 'pip'

            $script:capturedArgs = $null
            Mock -CommandName 'pip' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed requests' 
            }

            $result = Install-PythonPackage -Packages @('requests')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'install'
            $script:capturedArgs | Should -Contain 'requests'
        }

        It 'Calls installer with additional arguments' {
            Setup-AvailableCommandMock -CommandName 'uv'

            $script:capturedArgs = $null
            Mock -CommandName 'uv' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed package' 
            }

            $result = Install-PythonPackage -Packages @('pytest') -Arguments @('--dev')

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain '--dev'
        }
    }

    Context 'Error handling' {
        It 'Falls back to pip when uv fails' {
            Setup-AvailableCommandMock -CommandName 'uv'
            Setup-AvailableCommandMock -CommandName 'pip'

            Mock -CommandName 'uv' -MockWith {
                throw [System.Management.Automation.CommandNotFoundException]::new('uv: command failed')
            }

            $script:capturedArgs = $null
            Mock -CommandName 'pip' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                return 'Installed package' 
            }

            $result = Install-PythonPackage -Packages @('requests') -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $script:capturedArgs | Should -Contain 'install'
        }
    }
}

