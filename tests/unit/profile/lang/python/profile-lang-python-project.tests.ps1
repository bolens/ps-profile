# ===============================================
# profile-lang-python-project.tests.ps1
# Unit tests for New-PythonProject and Install-PythonPackage functions
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'lang-python-env.ps1')
    . (Join-Path $script:ProfileDir 'lang-python-packages.ps1')
    $script:ProjectRoot = New-TestTempDirectory -Prefix 'PythonProjectTest'
}

Describe 'lang-python.ps1 - New-PythonProject' {
    BeforeEach {
        Clear-TestCommandInvocationCapture
    }

    Context 'Project creation' {
        It 'Creates project directory structure' {
            $projectPath = New-PythonProject -Name 'testproject' -Path $script:ProjectRoot

            $projectPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $projectPath | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'README.md') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath '.gitignore') | Should -Be $true
            Test-Path -LiteralPath (Join-Path $projectPath 'main.py') | Should -Be $true
        }

        It 'Creates requirements.txt when uv is not available' {
            Mark-TestCommandsUnavailable -CommandNames 'uv'

            $projectPath = New-PythonProject -Name 'testproject2' -Path $script:ProjectRoot

            Test-Path -LiteralPath (Join-Path $projectPath 'requirements.txt') | Should -Be $true
        }

        It 'Uses uv init when UseUV is specified and uv is available' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Project initialized'

            $projectPath = New-PythonProject -Name 'testproject3' -Path $script:ProjectRoot -UseUV

            $projectPath | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'init'
        }

        It 'Does not overwrite existing files' {
            $projectPath = New-PythonProject -Name 'testproject4' -Path $script:ProjectRoot
            $readmePath = Join-Path $projectPath 'README.md'
            Set-Content -Path $readmePath -Value 'Custom README'

            $null = New-PythonProject -Name 'testproject4' -Path $script:ProjectRoot

            Get-Content -Path $readmePath | Should -Contain 'Custom README'
        }
    }
}

Describe 'lang-python.ps1 - Install-PythonPackage' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames @('uv', 'pip')
    }

    Context 'Tool not available' {
        It 'Returns null when neither uv nor pip is available' {
            $result = Install-PythonPackage -Packages @('requests') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Tool available' {
        It 'Prefers uv when available' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Installed requests'

            $result = Install-PythonPackage -Packages @('requests') -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'pip'
            $args | Should -Contain 'install'
            $args | Should -Contain 'requests'
            $result | Should -Be 'Installed requests'
        }

        It 'Falls back to pip when uv is not available' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Installed requests'
            Mark-TestCommandsUnavailable -CommandNames 'uv'

            $result = Install-PythonPackage -Packages @('requests') -ErrorAction SilentlyContinue

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'install'
            $args | Should -Contain 'requests'
            $result | Should -Be 'Installed requests'
        }

        It 'Calls installer with additional arguments' {
            Setup-CapturingCommandMock -CommandName 'uv' -Output 'Installed package'

            $params = @{
                Packages  = @('pytest')
                Arguments = @('--dev')
            }
            Install-PythonPackage @params -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--dev'
        }
    }

    Context 'Error handling' {
        It 'Falls back to pip when uv fails' {
            Setup-CapturingCommandMock -CommandName 'pip' -Output 'Installed package'

            $global:AssumedAvailableCommands['uv'] = $true
            $global:TestCachedCommandCache['uv'] = [pscustomobject]@{
                Result  = $true
                Expires = (Get-Date).AddHours(24)
            }
            $throwingUv = {
                throw [System.Management.Automation.CommandNotFoundException]::new('uv: command failed')
            }
            Set-Item -Path 'Function:\global:uv' -Value $throwingUv -Force
            Set-Item -Path 'Function:\uv' -Value $throwingUv -Force

            $result = Install-PythonPackage -Packages @('requests') -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'install'
        }
    }
}
