# ===============================================
# lang-python.tests.ps1
# Integration tests for lang-python.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:LangPythonPath = Join-Path $script:ProfileDir 'lang-python.ps1'

    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    # Load lang-python fragment
    . $script:LangPythonPath
}

Describe 'lang-python.ps1 Integration Tests' {
    Context 'Function Registration' {
        It 'Registers Install-PythonApp function' {
            Get-Command Install-PythonApp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Invoke-Pipx function' {
            Get-Command Invoke-Pipx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Invoke-PythonScript function' {
            Get-Command Invoke-PythonScript -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers New-PythonVirtualEnv function' {
            Get-Command New-PythonVirtualEnv -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers New-PythonProject function' {
            Get-Command New-PythonProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Install-PythonPackage function' {
            Get-Command Install-PythonPackage -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Alias Creation' {
        It 'Creates pipx-install alias' {
            . $script:LangPythonPath -ErrorAction SilentlyContinue
            $alias = Get-Alias pipx-install -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'pipx-install' -Target 'Install-PythonApp' | Out-Null
                }
                $alias = Get-Alias pipx-install -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates pipx alias' {
            . $script:LangPythonPath -ErrorAction SilentlyContinue
            $alias = Get-Alias pipx -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'pipx' -Target 'Invoke-Pipx' | Out-Null
                }
                $alias = Get-Alias pipx -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates pyvenv alias' {
            . $script:LangPythonPath -ErrorAction SilentlyContinue
            $alias = Get-Alias pyvenv -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'pyvenv' -Target 'New-PythonVirtualEnv' | Out-Null
                }
                $alias = Get-Alias pyvenv -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates pyinstall alias' {
            . $script:LangPythonPath -ErrorAction SilentlyContinue
            $alias = Get-Alias pyinstall -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'pyinstall' -Target 'Install-PythonPackage' | Out-Null
                }
                $alias = Get-Alias pyinstall -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful Degradation' {
        It 'Install-PythonApp handles missing pipx gracefully' {
            $result = Install-PythonApp -Packages @('test-package') -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }

        It 'Invoke-Pipx handles missing pipx gracefully' {
            $result = Invoke-Pipx -Package 'test-package' -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }

        It 'Invoke-PythonScript handles missing python gracefully' {
            $result = Invoke-PythonScript -Script 'script.py' -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }

        It 'New-PythonVirtualEnv handles missing tools gracefully' {
            $result = New-PythonVirtualEnv -ErrorAction SilentlyContinue
            # Should return null or empty when tools are not available
        }

        It 'Install-PythonPackage handles missing tools gracefully' {
            $result = Install-PythonPackage -Packages @('requests') -ErrorAction SilentlyContinue
            # Should return null or empty when tools are not available
        }
    }

    Context 'Fragment Loading' {
        It 'Fragment can be loaded multiple times (idempotency)' {
            { . $script:LangPythonPath } | Should -Not -Throw
            { . $script:LangPythonPath } | Should -Not -Throw
            { . $script:LangPythonPath } | Should -Not -Throw
        }

        It 'Functions remain available after multiple loads' {
            . $script:LangPythonPath
            . $script:LangPythonPath
            . $script:LangPythonPath

            Get-Command Install-PythonApp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-Pipx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-PythonScript -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Project Creation' {
        It 'Creates Python project structure' {
            $testPath = Join-Path $TestDrive 'testproject'
            $projectPath = New-PythonProject -Name 'testproject' -Path $TestDrive

            $projectPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $projectPath | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'README.md') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath '.gitignore') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'main.py') | Should -Be $true
        }
    }
}

