<#
tests/unit/library-python-path-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Python path resolution via environment variables.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
    }
}
