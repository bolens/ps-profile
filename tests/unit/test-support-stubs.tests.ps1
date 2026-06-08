<#
tests/unit/test-support-stubs.tests.ps1

.SYNOPSIS
    Unit tests for TestSupport stub modules (environment, terminal, reflection).
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot

    $bootstrapPath = Join-Path $script:TestRepoRoot 'profile.d/bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        . $bootstrapPath
    }
}

Describe 'TestEnvironmentStubs Module' {
    AfterEach {
        if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
            Restore-AllMocks
        }
    }

    Context 'Mock-EnvironmentVariable' {
        It 'Sets and restores a process environment variable' {
            $varName = "TEST_SUPPORT_STUB_$([Guid]::NewGuid().ToString('N'))"
            $original = 'original-value'
            Set-Item -Path "Env:\$varName" -Value $original -Force
            $testValue = 'stub-value-123'

            try {
                Mock-EnvironmentVariable -Name $varName -Value $testValue
                (Get-Item -Path "Env:\$varName").Value | Should -Be $testValue

                Restore-EnvironmentVariable -Name $varName
                (Get-Item -Path "Env:\$varName").Value | Should -Be $original
            }
            finally {
                Remove-Item -Path "Env:\$varName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Removes environment variable when Value is null' {
            $varName = "TEST_SUPPORT_STUB_$([Guid]::NewGuid().ToString('N'))"
            Set-Item -Path "Env:\$varName" -Value 'to-be-cleared' -Force

            try {
                Mock-EnvironmentVariable -Name $varName -Value $null
                Get-Item -Path "Env:\$varName" -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path "Env:\$varName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Mocks multiple variables via Mock-EnvironmentVariables' {
            $prefix = [Guid]::NewGuid().ToString('N')
            $vars = @{
                "TEST_MULTI_${prefix}_A" = 'alpha'
                "TEST_MULTI_${prefix}_B" = 'beta'
            }

            try {
                Mock-EnvironmentVariables -Variables $vars
                (Get-Item -Path "Env:\TEST_MULTI_${prefix}_A").Value | Should -Be 'alpha'
                (Get-Item -Path "Env:\TEST_MULTI_${prefix}_B").Value | Should -Be 'beta'
            }
            finally {
                foreach ($name in $vars.Keys) {
                    Remove-Item -Path "Env:\$name" -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context 'Register-Mock and Restore-AllMocks' {
        It 'Restores mocked functions via Restore-AllMocks' {
            $funcName = "TestStubFunc_$([Guid]::NewGuid().ToString('N'))"
            $original = { 'original' }
            Set-Item -Path "Function:\global:$funcName" -Value $original -Force

            Register-Mock -Type 'Function' -Name $funcName -MockValue { 'mocked' } -Original $original
            Set-Item -Path "Function:\global:$funcName" -Value { 'mocked' } -Force

            & $funcName | Should -Be 'mocked'

            Restore-AllMocks

            & $funcName | Should -Be 'original'
            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'TerminalTestStubs Module' {
    AfterEach {
        if (Get-Command Restore-TestTerminalStubs -ErrorAction SilentlyContinue) {
            Restore-TestTerminalStubs
        }
    }

    Context 'Write-Host capture' {
        It 'Captures Write-Host output' {
            Register-TestWriteHostCapture
            Write-Host 'hello' -NoNewline
            Write-Host ' world'

            Get-TestWriteHostCaptureCount | Should -Be 2
            Get-TestWriteHostOutputString | Should -Be 'hello world'
        }

        It 'Clears capture buffer' {
            Register-TestWriteHostCapture
            Write-Host 'line1'
            Clear-TestWriteHostCapture

            Get-TestWriteHostCaptureCount | Should -Be 0
            Get-TestWriteHostOutputString | Should -Be ''
        }
    }

    Context 'Get-History stub' {
        It 'Returns configured history and tracks invocations' {
            $history = @(
                [pscustomobject]@{ CommandLine = 'git status'; Id = 1 }
                [pscustomobject]@{ CommandLine = 'ls'; Id = 2 }
            )
            Register-TestGetHistoryStub -ReturnValue $history

            $result = Get-History
            $result.Count | Should -Be 2
            $result[0].CommandLine | Should -Be 'git status'

            Assert-TestGetHistoryInvoked -Times 1
        }
    }

    Context 'Clear-History stub' {
        It 'Tracks Clear-History invocations' {
            Register-TestClearHistoryStub
            Clear-History
            Assert-TestClearHistoryInvoked -Times 1
        }
    }

    Context 'Read-Host stub' {
        It 'Returns configured response without prompting' {
            Set-TestReadHostResponse -Response 'yes'
            Read-Host 'Continue?' | Should -Be 'yes'
        }
    }

    Context 'Get-Module stub' {
        It 'Returns configured module list' {
            $fakeModule = [pscustomobject]@{ Name = 'StubModule'; Path = '/tmp/stub' }
            Register-TestGetModuleStub -ReturnValue @($fakeModule)

            $modules = Get-Module
            $modules.Count | Should -Be 1
            $modules[0].Name | Should -Be 'StubModule'
        }
    }

    Context 'Profile function stub' {
        It 'Stubs and restores profile functions' {
            $funcName = "TestProfileStub_$([Guid]::NewGuid().ToString('N'))"
            Set-Item -Path "Function:\global:$funcName" -Value { 'real' } -Force

            Register-TestProfileFunctionStub -Name $funcName -Body { 'stubbed' }
            & $funcName | Should -Be 'stubbed'

            Restore-TestProfileFunctionStubs
            & $funcName | Should -Be 'real'

            Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'TestReflectionHelpers Module' {
    Context 'Invoke-MakeGenericTypeWrapper' {
        It 'Creates generic types from type definitions' {
            $listOpenGeneric = [System.Collections.Generic.List`1]
            $listType = $listOpenGeneric.MakeGenericType([string])
            $result = Invoke-MakeGenericTypeWrapper -GenericTypeDefinition $listOpenGeneric -TypeArguments @([string])
            $result | Should -Be $listType
        }

        It 'Returns null when ForceNull is set' {
            $listOpenGeneric = [System.Collections.Generic.List`1]
            Invoke-MakeGenericTypeWrapper -GenericTypeDefinition $listOpenGeneric -TypeArguments @([string]) -ForceNull |
                Should -BeNullOrEmpty
        }

        It 'Throws when ForceException is set' {
            $listOpenGeneric = [System.Collections.Generic.List`1]
            {
                Invoke-MakeGenericTypeWrapper -GenericTypeDefinition $listOpenGeneric -TypeArguments @([string]) -ForceException
            } | Should -Throw 'Mocked exception for testing'
        }
    }

    Context 'Invoke-CreateInstanceWrapper' {
        It 'Creates instances of reference types' {
            $result = Invoke-CreateInstanceWrapper -Type ([System.Text.StringBuilder])
            $result | Should -BeOfType ([System.Text.StringBuilder])
        }

        It 'Returns null when ForceNull is set' {
            Invoke-CreateInstanceWrapper -Type ([string]) -ForceNull | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-TypeConstructorWrapper' {
        It 'Invokes parameterless constructors' {
            $result = Invoke-TypeConstructorWrapper -Type ([System.Text.StringBuilder])
            $result | Should -BeOfType ([System.Text.StringBuilder])
        }

        It 'Throws when ForceException is set' {
            {
                Invoke-TypeConstructorWrapper -Type ([System.Text.StringBuilder]) -ForceException
            } | Should -Throw 'Mocked exception for testing'
        }
    }
}

Describe 'TestCommandAvailability Module' {
    AfterEach {
        Set-TestCommandAvailabilityState -CommandName 'stub-cmd-availability-test' -Available $false -ErrorAction SilentlyContinue
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Set-TestCommandAvailabilityState' {
        It 'Registers mock command when marked available' {
            Set-TestCommandAvailabilityState -CommandName 'stub-cmd-availability-test' -Available $true
            Get-Command 'stub-cmd-availability-test' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Test-CachedCommand -Name 'stub-cmd-availability-test' | Should -Be $true
        }

        It 'Reports command unavailable when marked unavailable' {
            Set-TestCommandAvailabilityState -CommandName 'stub-cmd-availability-test' -Available $false
            Test-CachedCommand -Name 'stub-cmd-availability-test' | Should -Be $false
        }
    }
}
