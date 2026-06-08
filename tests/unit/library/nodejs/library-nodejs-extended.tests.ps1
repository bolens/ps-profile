<#
tests/unit/library-nodejs-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for NodeJs path detection and script invocation guards.
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
    Import-Module (Join-Path $script:LibPath 'runtime' 'NodeJs.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'NodeJsExtended'
}

AfterAll {
    Remove-Module NodeJs -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'NodeJs extended scenarios' {
    Context 'Get-PnpmGlobalPath' {
        It 'Does not treat PNPM_HOME as global path when node_modules is missing beneath it' {
            $emptyHome = Join-Path $script:TempDir 'empty-pnpm-home'
            New-Item -ItemType Directory -Path $emptyHome -Force | Out-Null

            $original = $env:PNPM_HOME
            try {
                $env:PNPM_HOME = $emptyHome
                $result = Get-PnpmGlobalPath

                if ($null -ne $result) {
                    $result | Should -Not -Be (Join-Path $emptyHome 'node_modules')
                }
            }
            finally {
                $env:PNPM_HOME = $original
            }
        }

        It 'Prefers PNPM_HOME node_modules over other detection paths' {
            $pnpmHome = Join-Path $script:TempDir 'pnpm-home'
            $nodeModules = Join-Path $pnpmHome 'node_modules'
            New-Item -ItemType Directory -Path $nodeModules -Force | Out-Null

            $original = $env:PNPM_HOME
            try {
                $env:PNPM_HOME = $pnpmHome
                Get-PnpmGlobalPath | Should -Be $nodeModules
            }
            finally {
                $env:PNPM_HOME = $original
            }
        }
    }

    Context 'Invoke-NodeScript' {
        It 'Throws when the script path is outside the filesystem' {
            $missingScript = Join-Path $script:TempDir 'missing-script.js'

            { Invoke-NodeScript -ScriptPath $missingScript } | Should -Throw '*not found*'
        }

        It 'Accepts Arguments parameter for forwarding to node' {
            $command = Get-Command Invoke-NodeScript
            $command.Parameters.Keys | Should -Contain 'Arguments'
        }
    }
}
