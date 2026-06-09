<#
tests/unit/library-python-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Python path detection and install hint helpers.
#>

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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'runtime' 'Python.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'PythonExtended'
}

AfterAll {
    Remove-Module Python -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Python extended scenarios' {
    Context 'Get-PythonPath' {
        It 'Uses PYTHON env var when it points to an existing executable' {
            $fakePython = Join-Path $script:TempDir 'custom-python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            $original = $env:PYTHON
                        $env:PYTHON = $fakePython
            Get-PythonPath | Should -Be $fakePython
        }
        finally {
            $env:PYTHON = $original
        }

        It 'Uses CONDA_PREFIX when bin/python exists beneath it' {
            $condaRoot = Join-Path $script:TempDir 'conda-env'
            $condaBin = Join-Path $condaRoot 'bin'
            New-Item -ItemType Directory -Path $condaBin -Force | Out-Null
            $fakePython = Join-Path $condaBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh'

            $original = $env:CONDA_PREFIX
                        $env:CONDA_PREFIX = $condaRoot
            Get-PythonPath | Should -Be $fakePython
        }
        finally {
            $env:CONDA_PREFIX = $original
        }
    }

    Context 'Get-PythonPackageManagerPreference' {
        It 'Returns a hashtable with manager metadata keys' {
            $result = Get-PythonPackageManagerPreference

            $result | Should -Not -BeNullOrEmpty
            $result.Keys | Should -Contain 'Manager'
            $result.Keys | Should -Contain 'Available'
            $result.Keys | Should -Contain 'InstallCommand'
        }
    }

    Context 'Expand-EmbeddedPythonInstallHints' {
        It 'Replaces install placeholders with a recommendation command' {
            $scriptText = 'Run __PYTHON_INSTALL_CMD__ to continue'

            $expanded = Expand-EmbeddedPythonInstallHints -Script $scriptText -PackageNames @('requests')

            $expanded | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $expanded | Should -Match 'requests'
        }

        It 'Replaces placeholders via Resolve-PythonInstallHintMessage' {
            $message = 'Install packages: __PYTHON_INSTALL_CMD__'

            $resolved = Resolve-PythonInstallHintMessage -Message $message -PackageNames @('numpy')

            $resolved | Should -Not -Match '__PYTHON_INSTALL_CMD__'
            $resolved | Should -Match 'numpy'
        }

        It 'Returns the original script when no placeholder is present' {
            $scriptText = 'No install hint here'
            Expand-EmbeddedPythonInstallHints -Script $scriptText -PackageNames 'pandas' |
                Should -Be $scriptText
        }
    }
}
