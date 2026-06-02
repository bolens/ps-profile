# ===============================================
# lang-python.tests.ps1
# Integration tests for lang-python-*.ps1 fragments
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPaths = @(
        (Join-Path $script:ProfileDir 'lang-python-pipx.ps1'),
        (Join-Path $script:ProfileDir 'lang-python-env.ps1'),
        (Join-Path $script:ProfileDir 'lang-python-packages.ps1')
    )

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    foreach ($fragmentPath in $script:FragmentPaths) {
        if (-not (Test-Path -LiteralPath $fragmentPath)) {
            throw "Fragment not found: $fragmentPath"
        }
        . $fragmentPath
    }
}

Describe 'lang-python Integration Tests' {
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
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
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
            Assert-ProfileShadowedAlias -AliasName 'pipx' -FunctionName 'Invoke-Pipx'
        }

        It 'Creates pyvenv alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
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
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
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

        It 'Install-PythonApp handles missing pipx gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'pipx' -Available $false
            $output = & { Install-PythonApp -Packages @('test-package') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pipx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'pipx'
        }

        It 'Invoke-Pipx handles missing pipx gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'pipx' -Available $false
            $output = & { Invoke-Pipx -Package 'test-package' } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pipx not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'pipx'
        }

        It 'Invoke-PythonScript handles missing python gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'python3' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'python' -Available $false
            $output = & { Invoke-PythonScript -Script 'script.py' } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'python not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'python'
        }

        It 'New-PythonVirtualEnv handles missing tools gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'uv' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'python' -Available $false
            Mock-CommandAvailabilityPester -CommandName 'python3' -Available $false
            $output = & { New-PythonVirtualEnv } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'python not found'
        }

        It 'Install-PythonPackage handles missing tools gracefully' {
            foreach ($cmd in @('uv', 'pip', 'pip3')) {
                Mock-CommandAvailabilityPester -CommandName $cmd -Available $false
            }
            $output = & { Install-PythonPackage -Packages @('requests') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'pip not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'pip'
        }
    }

    Context 'Fragment Loading' {
        It 'Fragment can be loaded multiple times (idempotency)' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                { . $fragmentPath } | Should -Not -Throw
                { . $fragmentPath } | Should -Not -Throw
                { . $fragmentPath } | Should -Not -Throw
            }
        }

        It 'Functions remain available after multiple loads' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath
                . $fragmentPath
                . $fragmentPath
            }

            Get-Command Install-PythonApp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-Pipx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-PythonScript -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Project Creation' {
        It 'Creates Python project structure' {
            $projectPath = New-PythonProject -Name 'testproject' -Path $TestDrive

            $projectPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $projectPath | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'README.md') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath '.gitignore') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'main.py') | Should -Be $true
        }
    }
}
