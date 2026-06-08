<#
tests/unit/test-support-core-functions.tests.ps1

.SYNOPSIS
    Unit tests for TestSupportCoreFunctions and command mock helpers.
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

    $bootstrapPath = Join-Path $script:TestRepoRoot 'profile.d/bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        . $bootstrapPath
    }
}

Describe 'TestSupportCoreFunctions Module' {
    AfterEach {
        Set-TestCommandAvailabilityState -CommandName 'core-stub-cmd' -Available $false -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:core-stub-cmd' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\core-stub-cmd' -Force -ErrorAction SilentlyContinue
    }

    Context 'Mark-TestCommandsUnavailable' {
        It 'Caches commands as unavailable' {
            $commandName = "core-unavail_$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-Item -Path "Function:\global:$commandName" -Value { 'present' } -Force
                Test-CachedCommand -Name $commandName | Should -Be $true

                Mark-TestCommandsUnavailable -CommandNames $commandName
                Test-CachedCommand -Name $commandName | Should -Be $false
            }
            finally {
                Remove-Item -Path "Function:\global:$commandName" -Force -ErrorAction SilentlyContinue
                Remove-TestCachedCommandCacheEntry -Name $commandName -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    Context 'Register-TestFragmentAliases' {
        It 'Registers aliases when target functions exist' {
            $funcName = "CoreAliasTarget_$([Guid]::NewGuid().ToString('N'))"
            $aliasName = "core-alias-$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-Item -Path "Function:\global:$funcName" -Value { 'target' } -Force
                Register-TestFragmentAliases -AliasTargets @{ $aliasName = $funcName }

                Get-Alias -Name $aliasName -Scope Global -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Alias -Name $aliasName -Scope Global -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Import-ProfileFragmentWithShadowedCommands' {
        It 'Loads a fragment after hiding shadowing commands' {
            $tempDir = New-TestTempDirectory -Prefix 'CoreFragmentLoad'
            $shadowName = "shadow-cmd-$([Guid]::NewGuid().ToString('N'))"
            $fragmentPath = Join-Path $tempDir 'sample-fragment.ps1'
            $fragmentContent = @"
function global:Get-SampleFragmentValue {
    return 'loaded'
}
"@
            try {
                Set-Content -LiteralPath $fragmentPath -Value $fragmentContent -Encoding UTF8
                Set-Item -Path "Function:\global:$shadowName" -Value { 'host-binary' } -Force

                Import-ProfileFragmentWithShadowedCommands `
                    -FragmentPath $fragmentPath `
                    -ShadowCommandNames $shadowName

                Get-SampleFragmentValue | Should -Be 'loaded'
            }
            finally {
                Remove-Item -Path 'Function:\Get-SampleFragmentValue' -Force -ErrorAction SilentlyContinue
                Remove-Item -Path 'Function:\global:Get-SampleFragmentValue' -Force -ErrorAction SilentlyContinue
                Remove-Item -Path "Function:\global:$shadowName" -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'TestMocks command capture helpers' {
    AfterEach {
        if (Get-Command Clear-TestCommandInvocationCapture -ErrorAction SilentlyContinue) {
            Clear-TestCommandInvocationCapture
        }
        Set-TestCommandAvailabilityState -CommandName 'capture-mock-cmd' -Available $false -ErrorAction SilentlyContinue
    }

    Context 'Setup-CapturingCommandMock' {
        It 'Captures invocation arguments and returns configured output' {
            Setup-CapturingCommandMock -CommandName 'capture-mock-cmd' -Output 'mock-result'
            $result = & capture-mock-cmd 'arg1' '-Flag'

            $result | Should -Be 'mock-result'
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'arg1'
            $args | Should -Contain '-Flag'
        }

        It 'Honors configured exit codes' {
            Setup-CapturingCommandMock -CommandName 'capture-mock-cmd' -ExitCode 7 -Output ''
            $null = & capture-mock-cmd
            $LASTEXITCODE | Should -Be 7
        }

        It 'Invokes custom script blocks when provided' {
            Setup-CapturingCommandMock -CommandName 'capture-mock-cmd' -OnInvoke {
                return "handled:$($args -join ',')"
            }

            & capture-mock-cmd 'one' 'two' | Should -Be 'handled:one,two'
        }
    }

    Context 'Assert-TestCommandInvocationContains' {
        It 'Validates captured arguments' {
            Setup-CapturingCommandMock -CommandName 'capture-mock-cmd' -Output 'ok'
            $null = & capture-mock-cmd install package-name --quiet

            { Assert-TestCommandInvocationContains 'install', 'package-name' } | Should -Not -Throw
        }
    }

    Context 'Set-TestCommandThrowingMock' {
        It 'Throws when the mocked command is invoked' {
            Set-TestCommandThrowingMock -CommandName 'capture-mock-cmd' -Message 'capture-mock-cmd failed'
            { & capture-mock-cmd } | Should -Throw 'capture-mock-cmd failed'
        }
    }
}

Describe 'Package availability helpers' {
    Context 'Test-ScoopPackageAvailable' {
        It 'Returns false when scoop is unavailable' {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'scoop is installed on this host'
                return
            }

            Test-ScoopPackageAvailable -PackageName 'nonexistent-package-xyz' | Should -Be $false
        }
    }

    Context 'Test-LinuxSystemPackageAvailable' {
        It 'Returns false for unknown packages when pacman is available' {
            if (-not (Get-Command pacman -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'pacman is not available'
                return
            }

            Test-LinuxSystemPackageAvailable -PackageName 'zzz-nonexistent-pkg-xyz' -PackageManager 'pacman' | Should -Be $false
        }
    }
}
