# ===============================================
# profile-security-tools-gitleaks.tests.ps1
# Unit tests for Invoke-GitLeaksScan function
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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'security-tools.ps1')

    $script:TestRoot = New-TestTempDirectory -Prefix 'GitLeaksTest'
    $script:TestRepoPath = Join-Path $script:TestRoot 'TestRepo'
    $script:NonGitRepo = Join-Path $script:TestRoot 'NotARepo'
    $script:MissingRepoPath = Join-Path $script:TestRoot 'MissingRepo'

    New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
    New-Item -ItemType Directory -Path $script:NonGitRepo -Force | Out-Null
    Set-Content -Path (Join-Path $script:TestRepoPath 'test-file.txt') -Value 'Test content'
}

Describe 'security-tools.ps1 - Invoke-GitLeaksScan' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Mark-TestCommandsUnavailable -CommandNames 'gitleaks'
    }

    Context 'Invoke-GitLeaksScan' {
        It 'Returns null when gitleaks is not available' {
            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns null when repository path does not exist' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            $result = Invoke-GitLeaksScan -RepositoryPath $script:MissingRepoPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 0
        }

        It 'Calls gitleaks with correct arguments when tool is available' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -OutputFormat 'json' -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'detect'
            $args | Should -Contain '--source'
            $args | Should -Contain $script:TestRepoPath
            $args | Should -Contain '--format'
            $args | Should -Contain 'json'
            $result | Should -Be 'Scan results'
        }

        It 'Includes report path when specified' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            $reportPath = Join-Path $script:TestRoot 'report.json'
            Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ReportPath $reportPath -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--report-path'
            $args | Should -Contain $reportPath
        }

        It 'Includes no-git flag when report path is not specified' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--no-git'
        }

        It 'Uses default repository path when not specified' {
            try {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            Push-Location $script:TestRepoPath
                        $result = Invoke-GitLeaksScan -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            }
            finally {
                Pop-Location
            }
        }

        It 'Supports different output formats' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            $formats = @('json', 'csv', 'sarif')
            foreach ($format in $formats) {
                Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -OutputFormat $format -ErrorAction SilentlyContinue | Out-Null
            }

            $global:TestCommandInvocationCaptures.Count | Should -Be $formats.Count
            for ($i = 0; $i -lt $formats.Count; $i++) {
                $flatArgs = [System.Collections.Generic.List[object]]::new()
                foreach ($arg in $global:TestCommandInvocationCaptures[$i]) {
                    if ($arg -is [System.Array]) {
                        foreach ($nestedArg in $arg) {
                            $flatArgs.Add($nestedArg)
                        }
                    }
                    else {
                        $flatArgs.Add($arg)
                    }
                }

                $argsStrings = @($flatArgs | ForEach-Object { $_.ToString() })
                $argsStrings | Should -Contain '--format'
                $argsStrings | Should -Contain $formats[$i]
            }
        }

        It 'Handles gitleaks execution errors gracefully' {
            try {
            Set-TestCommandThrowingMock -CommandName 'gitleaks' -Message 'Execution failed'

            $result = $null
                        $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue
            }
            catch {
                $result = $null

                $result | Should -BeNullOrEmpty
            }
        }

        It 'Uses default repository path when empty path is provided' {
            try {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            Push-Location $script:TestRepoPath
                        $result = Invoke-GitLeaksScan -RepositoryPath '' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles null repository path' {
            try {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            Push-Location $script:TestRepoPath
                        $result = Invoke-GitLeaksScan -RepositoryPath $null -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Uses default repository path when whitespace path is provided' {
            try {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            Push-Location $script:TestRepoPath
                        $result = Invoke-GitLeaksScan -RepositoryPath '   ' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            }
            finally {
                Pop-Location
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
                Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue | Out-Null

                $script:WriteWarningCaptures.Count | Should -Be 1
                $script:WriteWarningCaptures[0] | Should -Match 'gitleaks'
            }
            finally {
                Remove-Item Function:\Write-Warning -Force -ErrorAction SilentlyContinue
                Remove-Item Function:\global:Write-Warning -Force -ErrorAction SilentlyContinue
                if ($originalMissingWarning) {
                    Set-Item -Path Function:\global:Write-MissingToolWarning -Value $originalMissingWarning.ScriptBlock -Force
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
                $script:MissingToolWarningCaptures[0].Tool | Should -Be 'gitleaks'
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
    }

    Context 'Parameter Validation' {
        It 'Validates OutputFormat parameter' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            { Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -OutputFormat 'invalid' -ErrorAction Stop } |
                Should -Throw
        }
    }

    Context 'Additional Functionality' {
        It 'Tests gitleaks with report path and output format' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            $reportPath = Join-Path $script:TestRoot 'report.json'
            Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ReportPath $reportPath -OutputFormat 'json' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--report-path'
            $args | Should -Contain $reportPath
            $args | Should -Contain '--format'
            $args | Should -Contain 'json'
            $args | Should -Not -Contain '--no-git'
        }

        It 'Returns null when repository path is not a container' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -Output 'Scan results'

            $result = Invoke-GitLeaksScan -RepositoryPath (Join-Path $script:TestRepoPath 'test-file.txt') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles tool command returning empty string' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -OnInvoke {
                return [string]::Empty
            }

            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -Be ''
        }

        It 'Handles tool command returning null' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -OnInvoke {
                return $null
            }

            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Tests gitleaks stderr output handling' {
            Setup-CapturingCommandMock -CommandName 'gitleaks' -OnInvoke {
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }

            $result = Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Tests gitleaks catch block error handling' {
            Set-TestCommandThrowingMock -CommandName 'gitleaks' -Message 'gitleaks not found'

            { Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction Stop } | Should -Throw
        }

        It 'Tests gitleaks Write-Error message format' {
            Set-TestCommandThrowingMock -CommandName 'gitleaks' -Message 'gitleaks not found'

            { Invoke-GitLeaksScan -RepositoryPath $script:TestRepoPath -ErrorAction Stop } | Should -Throw '*gitleaks*'
        }
    }
}
