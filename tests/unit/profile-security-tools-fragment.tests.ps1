# ===============================================
# profile-security-tools-fragment.tests.ps1
# Unit tests for fragment loading, registration, and requirements
# ===============================================

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:SecurityToolsPath = Join-Path $script:ProfileDir 'security-tools.ps1'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . $script:SecurityToolsPath

    # Create test directories
    if (Get-Variable -Name TestDrive -ErrorAction SilentlyContinue) {
        $script:TestRepoPath = Join-Path $TestDrive 'TestRepo'
        $script:TestFile = Join-Path $TestDrive 'test-file.txt'
        $script:TestRulesPath = Join-Path $TestDrive 'test-rules.yar'

        New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
        Set-Content -Path $script:TestFile -Value 'Test content'
        Set-Content -Path $script:TestRulesPath -Value 'rule TestRule { condition: true }'
    }
}

Describe 'security-tools.ps1 - Fragment Loading and Registration' {
    Context 'Function Registration' {
        It 'Registers Invoke-GitLeaksScan function' {
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers gitleaks-scan alias pointing to Invoke-GitLeaksScan' {
            Get-Alias gitleaks-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gitleaks-scan).ResolvedCommandName | Should -Be 'Invoke-GitLeaksScan'
        }

        It 'Registers Invoke-TruffleHogScan function' {
            Get-Command Invoke-TruffleHogScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers trufflehog-scan alias pointing to Invoke-TruffleHogScan' {
            Get-Alias trufflehog-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias trufflehog-scan).ResolvedCommandName | Should -Be 'Invoke-TruffleHogScan'
        }

        It 'Registers Invoke-OSVScan function' {
            Get-Command Invoke-OSVScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers osv-scan alias pointing to Invoke-OSVScan' {
            Get-Alias osv-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias osv-scan).ResolvedCommandName | Should -Be 'Invoke-OSVScan'
        }

        It 'Registers Invoke-YaraScan function' {
            Get-Command Invoke-YaraScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers yara-scan alias pointing to Invoke-YaraScan' {
            Get-Alias yara-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias yara-scan).ResolvedCommandName | Should -Be 'Invoke-YaraScan'
        }

        It 'Registers Invoke-ClamAVScan function' {
            Get-Command Invoke-ClamAVScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers clamav-scan alias pointing to Invoke-ClamAVScan' {
            Get-Alias clamav-scan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias clamav-scan).ResolvedCommandName | Should -Be 'Invoke-ClamAVScan'
        }

        It 'Registers Invoke-DangerzoneConvert function' {
            Get-Command Invoke-DangerzoneConvert -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers dangerzone-convert alias pointing to Invoke-DangerzoneConvert' {
            Get-Alias dangerzone-convert -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias dangerzone-convert).ResolvedCommandName | Should -Be 'Invoke-DangerzoneConvert'
        }
    }

    Context 'Fragment Loading' {
        It 'Fragment is idempotent (can be loaded multiple times)' {
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                . $script:SecurityToolsPath
            }
            # Functions should still be available after a second load
            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Function count does not increase after reload (Set-AgentModeFunction idempotency)' {
            $beforeCount = @(Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue).Count

            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                . $script:SecurityToolsPath
            }

            $afterCount = @(Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue).Count
            $afterCount | Should -Be $beforeCount -Because 'Set-AgentModeFunction is idempotent and should not create duplicate functions'
        }

        It 'gitleaks-scan alias still resolves correctly after reload' {
            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                . $script:SecurityToolsPath
            }
            $alias = Get-Alias gitleaks-scan -ErrorAction SilentlyContinue
            $alias | Should -Not -BeNullOrEmpty
            $alias.ResolvedCommandName | Should -Be 'Invoke-GitLeaksScan'
        }

        It 'Calls Test-FragmentLoaded when the helper is available' {
            function Test-FragmentLoaded {
                param([string]$FragmentName)
                return $true
            }

            Mock Get-Command -ParameterFilter { $Name -eq 'Test-FragmentLoaded' } -MockWith {
                return @{ Name = 'Test-FragmentLoaded' }
            }
            Mock Test-FragmentLoaded -MockWith {
                param([string]$FragmentName)
                return $true
            }

            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }

            Should -Invoke Test-FragmentLoaded -Times 1 -ParameterFilter { $FragmentName -eq 'security-tools' }
        }

        It 'Still loads all functions when Test-FragmentLoaded is not available' {
            Remove-Item -Path 'Function:\Test-FragmentLoaded' -Force -ErrorAction SilentlyContinue

            Mock Get-Command -ParameterFilter { $Name -eq 'Test-FragmentLoaded' } -MockWith {
                return $null
            }

            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }

            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Requirements Loading' {
        It 'Calls Set-FragmentLoaded when fragment loads successfully' {
            function Set-FragmentLoaded {
                param([string]$FragmentName)
            }

            Mock Get-Command -ParameterFilter { $Name -eq 'Set-FragmentLoaded' } -MockWith {
                return @{ Name = 'Set-FragmentLoaded' }
            }
            Mock Set-FragmentLoaded -MockWith {
                param([string]$FragmentName)
            }

            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }

            Should -Invoke Set-FragmentLoaded -Times 1 -ParameterFilter { $FragmentName -eq 'security-tools' }
        }

        It 'Calls Write-ProfileError when a fragment error occurs' {
            function Write-ProfileError {
                param(
                    [Parameter(Mandatory)]
                    [System.Management.Automation.ErrorRecord]$ErrorRecord,
                    [string]$Context,
                    [string]$Category
                )
            }

            Mock Get-Command -ParameterFilter { $Name -eq 'Write-ProfileError' } -MockWith {
                return @{ Name = 'Write-ProfileError' }
            }
            Mock Write-ProfileError -MockWith {
                param(
                    [Parameter(Mandatory)]
                    [System.Management.Automation.ErrorRecord]$ErrorRecord,
                    [string]$Context,
                    [string]$Category
                )
            }

            $tempFragment = Join-Path $TestDrive 'temp-security-tools.ps1'
            $fragmentContent = @'
try {
    throw "Test error"
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: security-tools' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load security-tools fragment: $($_.Exception.Message)"
    }
}
'@
            Set-Content -Path $tempFragment -Value $fragmentContent

            . $tempFragment -ErrorAction SilentlyContinue

            Should -Invoke Write-ProfileError -Times 1
        }

        It 'Falls back to Write-Warning when Write-ProfileError is not available' {
            Mock Write-Warning { }
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq 'Write-ProfileError' }

            $tempFragment = Join-Path $TestDrive 'temp-security-tools-warn.ps1'
            $fragmentContent = @'
try {
    throw "Test error"
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: security-tools' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load security-tools fragment: $($_.Exception.Message)"
    }
}
'@
            Set-Content -Path $tempFragment -Value $fragmentContent

            . $tempFragment -ErrorAction SilentlyContinue

            Should -Invoke Write-Warning -Times 1 -ParameterFilter { $Message -like '*Failed to load security-tools fragment*' }
        }
    }
}
