# ===============================================
# profile-security-tools-fragment.tests.ps1
# Unit tests for fragment loading, registration, and requirements
# ===============================================

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
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:SecurityToolsPath = Join-Path $script:ProfileDir 'security-tools.ps1'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . $script:SecurityToolsPath

    $script:TestWorkDir = New-TestTempDirectory -Prefix 'SecurityToolsFragment'
    $script:TestRepoPath = Join-Path $script:TestWorkDir 'TestRepo'
    $script:TestFile = Join-Path $script:TestWorkDir 'test-file.txt'
    $script:TestRulesPath = Join-Path $script:TestWorkDir 'test-rules.yar'

    New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
    Set-Content -Path $script:TestFile -Value 'Test content'
    Set-Content -Path $script:TestRulesPath -Value 'rule TestRule { condition: true }'
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
            $script:TestFragmentLoadedCalls = [System.Collections.Generic.List[string]]::new()
            $originalTestFragmentLoaded = Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue

            function global:Test-FragmentLoaded {
                param([string]$FragmentName)
                $null = $script:TestFragmentLoadedCalls.Add($FragmentName)
                return $true
            }

            try {
                if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                    Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                    . $script:SecurityToolsPath
                }

                $script:TestFragmentLoadedCalls.Count | Should -Be 1
                $script:TestFragmentLoadedCalls[0] | Should -Be 'security-tools'
            }
            finally {
                Remove-Item Function:\Test-FragmentLoaded -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Test-FragmentLoaded -Force -ErrorAction SilentlyContinue
                if ($originalTestFragmentLoaded) {
                    Set-Item -Path Function:\global:Test-FragmentLoaded -Value $originalTestFragmentLoaded.ScriptBlock -Force
                }
            }
        }

        It 'Still loads all functions when Test-FragmentLoaded is not available' {
            Remove-Item -Path 'Function:\Test-FragmentLoaded' -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\global:Test-FragmentLoaded' -Force -ErrorAction SilentlyContinue

            if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                . $script:SecurityToolsPath
            }

            Get-Command Invoke-GitLeaksScan -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Requirements Loading' {
        It 'Calls Set-FragmentLoaded when fragment loads successfully' {
            $script:SetFragmentLoadedCalls = [System.Collections.Generic.List[string]]::new()
            $originalSetFragmentLoaded = Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue

            function global:Set-FragmentLoaded {
                param([string]$FragmentName)
                $null = $script:SetFragmentLoadedCalls.Add($FragmentName)
            }

            Remove-Item -Path 'Function:\Test-FragmentLoaded' -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\global:Test-FragmentLoaded' -Force -ErrorAction SilentlyContinue

            try {
                if (Test-Path -LiteralPath $script:SecurityToolsPath) {
                    Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                    . $script:SecurityToolsPath
                }

                $script:SetFragmentLoadedCalls | Should -Contain 'security-tools'
            }
            finally {
                Remove-Item Function:\Set-FragmentLoaded -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Set-FragmentLoaded -Force -ErrorAction SilentlyContinue
                if ($originalSetFragmentLoaded) {
                    Set-Item -Path Function:\global:Set-FragmentLoaded -Value $originalSetFragmentLoaded.ScriptBlock -Force
                }
            }
        }

        It 'Calls Write-ProfileError when a fragment error occurs' {
            $script:WriteProfileErrorCallCount = 0
            $originalWriteProfileError = Get-Command Write-ProfileError -ErrorAction SilentlyContinue

            function global:Write-ProfileError {
                param(
                    [Parameter(Mandatory)]
                    [System.Management.Automation.ErrorRecord]$ErrorRecord,
                    [string]$Context,
                    [string]$Category
                )
                $script:WriteProfileErrorCallCount++
            }

            $tempFragment = Join-Path $script:TestWorkDir 'temp-security-tools.ps1'
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

            try {
                . $tempFragment -ErrorAction SilentlyContinue

                $script:WriteProfileErrorCallCount | Should -Be 1
            }
            finally {
                Remove-Item Function:\Write-ProfileError -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-ProfileError -Force -ErrorAction SilentlyContinue
                if ($originalWriteProfileError) {
                    Set-Item -Path Function:\global:Write-ProfileError -Value $originalWriteProfileError.ScriptBlock -Force
                }
            }
        }

        It 'Falls back to Write-Warning when Write-ProfileError is not available' {
            $script:CapturedWarnings = [System.Collections.Generic.List[string]]::new()

            Remove-Item -Path 'Function:\Write-ProfileError' -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\global:Write-ProfileError' -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\Write-Warning' -Force -ErrorAction SilentlyContinue
            Remove-Item -Path 'Function:\global:Write-Warning' -Force -ErrorAction SilentlyContinue

            function global:Write-Warning {
                param([string]$Message)
                $null = $script:CapturedWarnings.Add($Message)
            }

            $tempFragment = Join-Path $script:TestWorkDir 'temp-security-tools-warn.ps1'
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

            try {
                . $tempFragment -ErrorAction SilentlyContinue

                @($script:CapturedWarnings | Where-Object { $_ -like '*Failed to load security-tools fragment*' }).Count | Should -Be 1
            }
            finally {
                Remove-Item Function:\Write-Warning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-Warning -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
