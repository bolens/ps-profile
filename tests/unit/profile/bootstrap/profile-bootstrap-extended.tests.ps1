<#
tests/unit/profile-bootstrap-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for profile.d/bootstrap.ps1 orchestrator behavior.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:BootstrapPath = Join-Path $script:TestRepoRoot 'profile.d/bootstrap.ps1'
    $script:BootstrapDir = Join-Path $script:TestRepoRoot 'profile.d/bootstrap'

    . $script:BootstrapPath
}

Describe 'bootstrap.ps1 extended scenarios' {
    Context 'Load order' {
        It 'Loads GlobalState before downstream bootstrap modules during execution' {
            $loadOrder = @(
                'GlobalState.ps1',
                'ErrorHandlingStandard.ps1',
                'CommandCache.ps1',
                'FunctionRegistration.ps1',
                'ModulePathCache.ps1',
                'ModuleLoading.ps1'
            )

            $content = Get-Content -LiteralPath $script:BootstrapPath -Raw
            $positions = foreach ($moduleName in $loadOrder) {
                $content.IndexOf($moduleName)
            }

            $positions | Should -Not -Contain -1
            for ($index = 0; $index -lt ($positions.Count - 1); $index++) {
                $positions[$index] | Should -BeLessThan $positions[$index + 1]
            }
        }

        It 'Dot-sources expected bootstrap module files from profile.d/bootstrap' {
            foreach ($moduleName in @(
                    'GlobalState.ps1', 'ErrorHandlingStandard.ps1', 'FunctionRegistration.ps1',
                    'ModuleLoading.ps1', 'UserHome.ps1', 'PlatformPaths.ps1'
                )) {
                Test-Path -LiteralPath (Join-Path $script:BootstrapDir $moduleName) | Should -Be $true
            }
        }
    }

    Context 'Runtime helpers' {
        It 'Registers Set-AgentModeFunction after bootstrap load' {
            Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Test-CachedCommand after bootstrap load' {
            Get-Command Test-CachedCommand -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Initializes AssumedAvailableCommands global registry' {
            $global:AssumedAvailableCommands | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Idempotency' {
        It 'Allows a second bootstrap load without throwing' {
            . $script:BootstrapPath
            Get-Command Set-AgentModeFunction -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It 'Preserves existing function bodies on repeated Set-AgentModeFunction calls' {
            $funcName = "BootstrapExtended_$([Guid]::NewGuid().ToString('N'))"
                        Set-AgentModeFunction -Name $funcName -Body { 'first-body' } | Should -Be $true
            Set-AgentModeFunction -Name $funcName -Body { 'second-body' } | Should -Be $false
            & $funcName | Should -Be 'first-body'
        }
        finally {
            Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Failure handling' {
        It 'Continues loading other bootstrap helpers when a non-critical module fails' {
            $modulePath = Join-Path $script:BootstrapDir 'UserHome.ps1'
            $originalBytes = Backup-TestFileBytes -Path $modulePath
            $previousDebug = $env:PS_PROFILE_DEBUG

            try {
                Write-TestFileLiteralContent -Path $modulePath -Content 'throw "bootstrap extended failure"'
                Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

                . $script:BootstrapPath

                Get-Command Set-AgentModeFunction -ErrorAction Stop | Should -Not -BeNullOrEmpty
                Get-Command Import-FragmentModules -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Restore-TestFileBytes -Path $modulePath -Bytes $originalBytes
                if ($null -eq $previousDebug) {
                    Remove-Item Env:\PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $previousDebug
                }
            }
        }
    }
}
