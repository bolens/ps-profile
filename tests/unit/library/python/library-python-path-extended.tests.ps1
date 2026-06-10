<#
tests/unit/library-python-path-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Python path resolution via environment variables.
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

    $script:TempRoot = New-TestTempDirectory -Prefix 'PythonPathExtended'
}

AfterAll {
    Remove-Module Python -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Python path resolution extended scenarios' {
    Context 'Get-PythonPath' {
        It 'Uses the PYTHON environment variable when it points to an executable' {
            $fakePython = Join-Path $script:TempRoot 'custom-python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalPython = $env:PYTHON
            $originalVirtualEnv = $env:VIRTUAL_ENV
            try {
                Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
                $env:PYTHON = $fakePython

                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                $env:PYTHON = $originalPython
                $env:VIRTUAL_ENV = $originalVirtualEnv
            }
        }

        It 'Uses CONDA_PREFIX when a conda environment is configured' {
            $condaRoot = Join-Path $script:TempRoot 'conda-env'
            $condaBin = Join-Path $condaRoot 'bin'
            New-Item -ItemType Directory -Path $condaBin -Force | Out-Null
            $fakePython = Join-Path $condaBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalConda = $env:CONDA_PREFIX
            $originalPython = $env:PYTHON
            $originalVirtualEnv = $env:VIRTUAL_ENV
            try {
                Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
                $env:CONDA_PREFIX = $condaRoot

                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                $env:CONDA_PREFIX = $originalConda
                $env:PYTHON = $originalPython
                $env:VIRTUAL_ENV = $originalVirtualEnv
            }
        }

        It 'Uses PYTHON_HOME when it contains a bin/python executable' {
            $pythonHome = Join-Path $script:TempRoot 'python-home'
            $pythonBin = Join-Path $pythonHome 'bin'
            New-Item -ItemType Directory -Path $pythonBin -Force | Out-Null
            $fakePython = Join-Path $pythonBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalHome = $env:PYTHON_HOME
            $originalPython = $env:PYTHON
            $originalConda = $env:CONDA_PREFIX
            $originalVirtualEnv = $env:VIRTUAL_ENV
            try {
                Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                Remove-Item Env:CONDA_PREFIX -ErrorAction SilentlyContinue
                Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
                $env:PYTHON_HOME = $pythonHome

                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                $env:PYTHON_HOME = $originalHome
                $env:PYTHON = $originalPython
                $env:CONDA_PREFIX = $originalConda
                $env:VIRTUAL_ENV = $originalVirtualEnv
            }
        }

        It 'Emits level 3 debug when PYTHON_ROOT resolves python' {
            $pythonRoot = Join-Path $script:TempRoot 'python-root-debug'
            $pythonBin = Join-Path $pythonRoot 'bin'
            New-Item -ItemType Directory -Path $pythonBin -Force | Out-Null
            $fakePython = Join-Path $pythonBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalRoot = $env:PYTHON_ROOT
            $originalDebug = $env:PS_PROFILE_DEBUG
            try {
                Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                Remove-Item Env:CONDA_PREFIX -ErrorAction SilentlyContinue
                Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
                $env:PYTHON_ROOT = $pythonRoot
                $env:PS_PROFILE_DEBUG = '3'
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                $env:PYTHON_ROOT = $originalRoot
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Uses PYTHON_ROOT when it contains a bin/python executable' {
            $pythonRoot = Join-Path $script:TempRoot 'python-root'
            $pythonBin = Join-Path $pythonRoot 'bin'
            New-Item -ItemType Directory -Path $pythonBin -Force | Out-Null
            $fakePython = Join-Path $pythonBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalRoot = $env:PYTHON_ROOT
            $originalPython = $env:PYTHON
            $originalConda = $env:CONDA_PREFIX
            $originalVirtualEnv = $env:VIRTUAL_ENV
            try {
                Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                Remove-Item Env:CONDA_PREFIX -ErrorAction SilentlyContinue
                Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
                $env:PYTHON_ROOT = $pythonRoot

                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                $env:PYTHON_ROOT = $originalRoot
                $env:PYTHON = $originalPython
                $env:CONDA_PREFIX = $originalConda
                $env:VIRTUAL_ENV = $originalVirtualEnv
            }
        }

        It 'Uses VIRTUAL_ENV when bin/python exists beneath it' {
            $venvRoot = Join-Path $script:TempRoot 'virtual-env'
            $venvBin = Join-Path $venvRoot 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalVirtualEnv = $env:VIRTUAL_ENV
            $originalPython = $env:PYTHON
            try {
                Remove-Item Env:PYTHON -ErrorAction SilentlyContinue
                $env:VIRTUAL_ENV = $venvRoot

                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                $env:VIRTUAL_ENV = $originalVirtualEnv
                $env:PYTHON = $originalPython
            }
        }

        It 'Honors PS_PYTHON_RUNTIME when set to python3' {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'python3') {
                    return [PSCustomObject]@{ Name = 'python3' }
                }

                return Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
            } -ModuleName Python

            $originalRuntime = $env:PS_PYTHON_RUNTIME
            try {
                $env:PS_PYTHON_RUNTIME = 'python3'
                Get-PythonPath -RepoRoot (Join-Path $script:TempRoot 'runtime-root') | Should -Be 'python3'
            }
            finally {
                $env:PS_PYTHON_RUNTIME = $originalRuntime
            }
        }

        It 'Resolves venv python with level 2 debug output enabled' {
            $repoRoot = Join-Path $script:TempRoot 'repo-debug-venv'
            $venvBin = Join-Path $repoRoot '.venv' 'bin'
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'
            try {
                Get-PythonPath -RepoRoot $repoRoot | Should -Be $fakePython
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Detects repository root from a .git directory when RepoRoot is omitted' {
            $repoRoot = Join-Path $script:TempRoot 'git-detect-repo'
            $gitDir = Join-Path $repoRoot '.git'
            $venvBin = Join-Path $repoRoot '.venv' 'bin'
            New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
            New-Item -ItemType Directory -Path $venvBin -Force | Out-Null
            $fakePython = Join-Path $venvBin 'python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            Get-PythonPath -RepoRoot $repoRoot | Should -Be $fakePython
        }
    }

    Context 'Get-PythonPath without Validation helpers' {
        BeforeEach {
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
        }

        It 'Uses manual path validation when Test-ValidPath is unavailable' {
            $fakePython = Join-Path $script:TempRoot 'manual-validation-python'
            Set-Content -LiteralPath $fakePython -Value '#!/bin/sh' -Encoding UTF8

            $originalPython = $env:PYTHON
            try {
                Remove-Item Env:VIRTUAL_ENV -ErrorAction SilentlyContinue
                $env:PYTHON = $fakePython
                Get-PythonPath | Should -Be $fakePython
            }
            finally {
                $env:PYTHON = $originalPython
            }
        }
    }
}
