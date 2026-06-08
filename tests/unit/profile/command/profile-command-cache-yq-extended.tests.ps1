<#
tests/unit/profile-command-cache-yq-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for yq-specific CommandCache helpers.
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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'CommandCache.ps1')
}

Describe 'CommandCache yq extended scenarios' {
    Context 'Get-ExternalCommandLookupNames' {
        It 'Returns go-yq and yq lookup candidates for yq commands' {
            Get-ExternalCommandLookupNames -Name 'yq' | Should -Be @('go-yq', 'yq')
        }

        It 'Returns a single normalized name for non-yq commands' {
            Get-ExternalCommandLookupNames -Name '  docker  ' | Should -Be @('docker')
        }
    }

    Context 'Test-IsMikefarahYqExecutable' {
        It 'Rejects python-yq executables that expose jq_filter help text' {
            $stubName = "python-yq-stub-$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-Item -Path "Function:\global:$stubName" -Value {
                    if ($args -contains '--version') {
                        Write-Output 'yq 0.0.1'
                        return
                    }
                    if ($args -contains 'eval' -and $args -contains '--help') {
                        Write-Output 'jq_filter usage'
                        return
                    }
                    Write-Output 'help'
                } -Force

                Test-IsMikefarahYqExecutable -Executable $stubName | Should -Be $false
            }
            finally {
                Remove-Item -Path "Function:\global:$stubName" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Accepts executables whose eval help mentions evaluates' {
            $stubName = "mikefarah-yq-stub-$([Guid]::NewGuid().ToString('N'))"
            try {
                Set-Item -Path "Function:\global:$stubName" -Value {
                    if ($args -contains 'eval' -and $args -contains '--help') {
                        Write-Output 'evaluates YAML documents'
                        return
                    }
                    Write-Output 'help'
                } -Force

                Test-IsMikefarahYqExecutable -Executable $stubName | Should -Be $true
            }
            finally {
                Remove-Item -Path "Function:\global:$stubName" -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Invoke-CachedYqCommand' {
        AfterEach {
            if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
                Clear-TestCommandAvailabilityStub
            }
            Clear-TestCachedCommandCache | Out-Null
        }

        It 'Forwards arguments to the resolved yq executable' {
            $stubName = "yq-args-stub-$([Guid]::NewGuid().ToString('N'))"
            $script:YqArgsReceived = $null
            try {
                Set-Item -Path "Function:\global:$stubName" -Value {
                    $script:YqArgsReceived = $args
                    Write-Output 'yq-stub-ok'
                } -Force

                Set-TestCommandAvailabilityState -CommandName 'yq' -Available $true
                Mock Get-CachedExternalCommand { return (Get-Command -Name $stubName) }

                $output = Invoke-CachedYqCommand --version
                $output | Should -Be 'yq-stub-ok'
                $script:YqArgsReceived | Should -Contain '--version'
            }
            finally {
                Remove-Item -Path "Function:\global:$stubName" -Force -ErrorAction SilentlyContinue
                $script:YqArgsReceived = $null
            }
        }
    }
}
