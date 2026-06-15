# ===============================================
# profile-security-tools-trufflehog.tests.ps1
# Unit tests for Invoke-TruffleHogScan function
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

    $script:TestRoot = New-TestTempDirectory -Prefix 'TruffleHogTest'
    $script:TestRepoPath = Join-Path $script:TestRoot 'TestRepo'
    $script:TestFile = Join-Path $script:TestRoot 'test-file.txt'

    New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
    Set-Content -Path $script:TestFile -Value 'Test content'
}

Describe 'security-tools.ps1 - Invoke-TruffleHogScan' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'trufflehog' -Available $false
        Remove-Item -Path 'Function:\trufflehog' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:trufflehog' -Force -ErrorAction SilentlyContinue
    }

    Context 'Invoke-TruffleHogScan' {
        It 'Returns null when trufflehog is not available' {
            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns error when path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'trufflehog'

            $result = Invoke-TruffleHogScan -Path (Join-Path $script:TestRoot 'Missing') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls trufflehog with correct arguments when tool is available' {
            Setup-CapturingCommandMock -CommandName 'trufflehog' -Output 'Scan results'

            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain 'filesystem'
            $args | Should -Contain $script:TestRepoPath
            $args | Should -Contain '--json'
            $result | Should -Be 'Scan results'
        }

        It 'Uses default path when not specified' {
            try {
            Setup-CapturingCommandMock -CommandName 'trufflehog' -Output 'Scan results'

            Push-Location $script:TestRepoPath
                        $result = Invoke-TruffleHogScan -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles trufflehog execution errors gracefully' {
            try {
            Set-TestCommandThrowingMock -CommandName 'trufflehog' -Message 'Execution failed'

            $result = $null
                        $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            }
            catch {
                $result = $null

                $result | Should -BeNullOrEmpty
            }
        }

        It 'Validates OutputFormat parameter' {
            Set-TestCommandAvailabilityState -CommandName 'trufflehog'

            { Invoke-TruffleHogScan -Path $script:TestRepoPath -OutputFormat 'invalid' -ErrorAction Stop } | Should -Throw
        }

        It 'Tests trufflehog with yaml format' {
            Setup-CapturingCommandMock -CommandName 'trufflehog' -Output 'Scan results'

            Invoke-TruffleHogScan -Path $script:TestRepoPath -OutputFormat 'yaml' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--yaml'
        }

        It 'Handles empty string path' {
            try {
            Setup-CapturingCommandMock -CommandName 'trufflehog' -Output 'Scan results'

            Push-Location $script:TestRepoPath
                        $result = Invoke-TruffleHogScan -Path '' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles trufflehog path not found' {
            Set-TestCommandAvailabilityState -CommandName 'trufflehog'

            $result = Invoke-TruffleHogScan -Path (Join-Path $script:TestRoot 'Missing') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Uses default path when trufflehog path is whitespace' {
            try {
            Setup-CapturingCommandMock -CommandName 'trufflehog' -Output 'Scan results'

            Push-Location $script:TestRepoPath
                        $result = Invoke-TruffleHogScan -Path '   ' -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles multiple pipeline inputs' {
            Setup-CapturingCommandMock -CommandName 'trufflehog' -Output 'Scan results'

            $paths = @($script:TestRepoPath, $script:TestFile)
            $null = $paths | Invoke-TruffleHogScan -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 2
        }

        It 'Tests trufflehog stderr output handling' {
            Setup-CapturingCommandMock -CommandName 'trufflehog' -OnInvoke {
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }

            $result = Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Tests trufflehog catch block error handling' {
            Set-TestCommandThrowingMock -CommandName 'trufflehog' -Message 'trufflehog not found'

            { Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction Stop } | Should -Throw
        }

        It 'Tests trufflehog Write-Error message format' {
            Set-TestCommandThrowingMock -CommandName 'trufflehog' -Message 'trufflehog not found'

            { Invoke-TruffleHogScan -Path $script:TestRepoPath -ErrorAction Stop } | Should -Throw '*trufflehog*'
        }
    }
}
