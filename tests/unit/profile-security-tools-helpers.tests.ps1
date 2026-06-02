# ===============================================
# profile-security-tools-helpers.tests.ps1
# Unit tests for missing-tool helper integration in security-tools.ps1
# ===============================================

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'security-tools.ps1')

    $script:TestRoot = New-TestTempDirectory -Prefix 'SecurityToolsHelpers'
    $script:TestRepoPath = Join-Path $script:TestRoot 'TestRepo'

    New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
    Set-Content -Path (Join-Path $script:TestRepoPath 'test-file.txt') -Value 'Test content'
}

Describe 'security-tools.ps1 - Missing Tool Helpers' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        if (Get-Command Clear-MissingToolWarnings -ErrorAction SilentlyContinue) {
            Clear-MissingToolWarnings | Out-Null
        }

        if ($global:CollectedMissingToolWarnings) {
            $global:CollectedMissingToolWarnings.Clear()
        }

        Mark-TestCommandsUnavailable -CommandNames @('gitleaks', 'trufflehog', 'osv-scanner', 'yara', 'clamscan')
    }

    Context 'Invoke-MissingToolWarning via security scanners' {
        It 'Uses Write-MissingToolWarning when gitleaks is missing' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Write-MissingToolWarning {
                param(
                    [string]$Tool,
                    [string]$InstallHint
                )
                $null = $script:MissingToolWarningCaptures.Add(@{
                        Tool        = $Tool
                        InstallHint = $InstallHint
                    })
            }

            try {
                Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue | Out-Null

                $script:MissingToolWarningCaptures.Count | Should -Be 1
                $script:MissingToolWarningCaptures[0].Tool | Should -Be 'gitleaks'
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match 'Install with:'
            }
            finally {
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }

        It 'Uses Write-MissingToolWarning when trufflehog is missing' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            function global:Write-MissingToolWarning {
                param(
                    [string]$Tool,
                    [string]$InstallHint
                )
                $null = $script:MissingToolWarningCaptures.Add(@{
                        Tool        = $Tool
                        InstallHint = $InstallHint
                    })
            }

            try {
                Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue | Out-Null

                $script:MissingToolWarningCaptures.Count | Should -Be 1
                $script:MissingToolWarningCaptures[0].Tool | Should -Be 'trufflehog'
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match 'Install with:'
            }
            finally {
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }

        It 'Uses default install command when Get-PreferenceAwareInstallHint is unavailable' {
            $script:MissingToolWarningCaptures = [System.Collections.Generic.List[hashtable]]::new()
            $originalHint = Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue
            $originalWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            Remove-Item Function:\Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Get-PreferenceAwareInstallHint -Force -ErrorAction SilentlyContinue

            function global:Write-MissingToolWarning {
                param(
                    [string]$Tool,
                    [string]$InstallHint
                )
                $null = $script:MissingToolWarningCaptures.Add(@{
                        Tool        = $Tool
                        InstallHint = $InstallHint
                    })
            }

            try {
                Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue | Out-Null

                $script:MissingToolWarningCaptures.Count | Should -Be 1
                $expectedInstall = Get-ToolInstallationCommand -ToolName 'gitleaks'
                $script:MissingToolWarningCaptures[0].InstallHint | Should -Match ([regex]::Escape($expectedInstall))
            }
            finally {
                Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
                if ($originalHint) {
                    Set-Item -Path Function:\global:Get-PreferenceAwareInstallHint -Value $originalHint.ScriptBlock -Force
                }
                if ($originalWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalWarning.ScriptBlock -Force
                }
            }
        }

        It 'Falls back to Write-Warning when Write-MissingToolWarning is unavailable' {
            $script:WriteWarningCaptures = [System.Collections.Generic.List[string]]::new()
            $originalMissingWarning = Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue

            Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue

            function global:Write-Warning {
                param([string]$Message)
                $null = $script:WriteWarningCaptures.Add($Message)
            }

            try {
                Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue | Out-Null

                $script:WriteWarningCaptures.Count | Should -Be 1
                $script:WriteWarningCaptures[0] | Should -Match 'trufflehog'
            }
            finally {
                Remove-Item Function:\Write-Warning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-Warning -Force -ErrorAction SilentlyContinue
                if ($originalMissingWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalMissingWarning.ScriptBlock -Force
                }
            }
        }
    }

    Context 'Get-PreferenceAwareInstallHint for security tools' {
        It 'Returns install hint for gitleaks' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'gitleaks'

            $hint | Should -Not -BeNullOrEmpty
            $hint | Should -Match 'Install with:'
            $hint | Should -Match 'gitleaks'
        }

        It 'Returns install hint for trufflehog' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'trufflehog'

            $hint | Should -Not -BeNullOrEmpty
            $hint | Should -Match 'Install with:'
            $hint | Should -Match 'trufflehog'
        }

        It 'Returns install hint for yara' {
            $hint = Get-PreferenceAwareInstallHint -ToolName 'yara'

            $hint | Should -Not -BeNullOrEmpty
            $hint | Should -Match 'Install with:'
            $hint | Should -Match 'yara'
        }
    }

    Context 'Write-MissingToolWarning collection' {
        BeforeEach {
            Remove-Item Function:\Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Write-MissingToolWarning -Force -ErrorAction SilentlyContinue
            . (Join-Path (Join-Path $script:ProfileDir 'bootstrap') 'MissingToolWarnings.ps1')

            if (Get-Command Clear-MissingToolWarnings -ErrorAction SilentlyContinue) {
                Clear-MissingToolWarnings | Out-Null
            }

            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
        }

        It 'Records warnings in CollectedMissingToolWarnings' {
            Write-MissingToolWarning -Tool 'gitleaks' -InstallHint 'Install with: scoop install gitleaks' -Force

            $global:CollectedMissingToolWarnings.Count | Should -BeGreaterThan 0
            $entry = $global:CollectedMissingToolWarnings | Where-Object { $_.Tool -eq 'gitleaks' } | Select-Object -First 1
            $entry | Should -Not -BeNullOrEmpty
            $entry.InstallHint | Should -Match 'scoop install gitleaks'
        }

        It 'Dedupes repeated warnings for the same tool' {
            Write-MissingToolWarning -Tool 'trufflehog' -InstallHint 'Install with: scoop install trufflehog'
            Write-MissingToolWarning -Tool 'trufflehog' -InstallHint 'Install with: scoop install trufflehog'

            @($global:CollectedMissingToolWarnings | Where-Object { $_.Tool -eq 'trufflehog' }).Count | Should -Be 1
        }
    }
}
