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
    $script:BootstrapContent = Get-Content -LiteralPath $script:BootstrapPath -Raw

    . $script:BootstrapPath
}

Describe 'bootstrap.ps1 extended scenarios' {
    Context 'Load order' {
        It 'Loads GlobalState before ErrorHandlingStandard' {
            $globalStateIndex = $script:BootstrapContent.IndexOf('GlobalState.ps1')
            $errorHandlingIndex = $script:BootstrapContent.IndexOf('ErrorHandlingStandard.ps1')
            $globalStateIndex | Should -BeGreaterThan (-1)
            $errorHandlingIndex | Should -BeGreaterThan (-1)
            $globalStateIndex | Should -BeLessThan $errorHandlingIndex
        }

        It 'Loads CommandCache after GlobalState initialization' {
            $globalStateIndex = $script:BootstrapContent.IndexOf('GlobalState.ps1')
            $commandCacheIndex = $script:BootstrapContent.IndexOf('CommandCache.ps1')
            $globalStateIndex | Should -BeGreaterThan (-1)
            $commandCacheIndex | Should -BeGreaterThan (-1)
            $globalStateIndex | Should -BeLessThan $commandCacheIndex
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
            { . $script:BootstrapPath } | Should -Not -Throw
        }

        It 'Preserves existing function bodies on repeated Set-AgentModeFunction calls' {
            $funcName = "BootstrapExtended_$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-AgentModeFunction -Name $funcName -Body { 'first-body' } | Should -Be $true
                Set-AgentModeFunction -Name $funcName -Body { 'second-body' } | Should -Be $false
                & $funcName | Should -Be 'first-body'
            }
            finally {
                Remove-Item -Path "Function:\$funcName" -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Failure handling' {
        It 'Swallows module load failures unless PS_PROFILE_DEBUG is enabled' {
            $script:BootstrapContent | Should -Match 'PS_PROFILE_DEBUG'
            $script:BootstrapContent | Should -Match 'Write-ProfileError'
        }
    }
}
