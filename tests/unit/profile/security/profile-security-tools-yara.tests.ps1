# ===============================================
# profile-security-tools-yara.tests.ps1
# Unit tests for Invoke-YaraScan function
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

    $script:TestRoot = New-TestTempDirectory -Prefix 'YaraScanTest'
    $script:TestRepoPath = Join-Path $script:TestRoot 'TestRepo'
    $script:TestFile = Join-Path $script:TestRoot 'test-file.txt'
    $script:TestRulesPath = Join-Path $script:TestRoot 'test-rules.yar'

    New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
    Set-Content -Path $script:TestFile -Value 'Test content'
    Set-Content -Path $script:TestRulesPath -Value 'rule TestRule { condition: true }'
}

Describe 'security-tools.ps1 - Invoke-YaraScan' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'yara' -Available $false
        Remove-Item -Path 'Function:\yara' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:yara' -Force -ErrorAction SilentlyContinue
    }

    Context 'Invoke-YaraScan' {
        It 'Returns null when yara is not available' {
            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns error when file path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'yara'

            $result = Invoke-YaraScan -FilePath (Join-Path $script:TestRoot 'Missing.txt') -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns error when rules path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'yara'

            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath (Join-Path $script:TestRoot 'Missing.yar') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls yara with correct arguments when tool is available' {
            Setup-CapturingCommandMock -CommandName 'yara' -Output 'Scan results'

            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain $script:TestRulesPath
            $args | Should -Contain $script:TestFile
            $result | Should -Be 'Scan results'
        }

        It 'Includes recursive flag when specified' {
            Setup-CapturingCommandMock -CommandName 'yara' -Output 'Scan results'

            Invoke-YaraScan -FilePath $script:TestRepoPath -RulesPath $script:TestRulesPath -Recursive -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-r'
        }

        It 'Handles YARA file path not found' {
            Set-TestCommandAvailabilityState -CommandName 'yara'

            $result = Invoke-YaraScan -FilePath (Join-Path $script:TestRoot 'Missing.exe') -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles YARA rules path not found' {
            Set-TestCommandAvailabilityState -CommandName 'yara'

            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath (Join-Path $script:TestRoot 'Missing.yar') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles yara execution errors gracefully' {
            Set-TestCommandThrowingMock -CommandName 'yara' -Message 'Execution failed'

            $result = $null
            try {
                $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue
            }
            catch {
                $result = $null
            }

            $result | Should -BeNullOrEmpty
        }

        It 'Tests yara with recursive flag' {
            Setup-CapturingCommandMock -CommandName 'yara' -Output 'Scan results'

            Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -Recursive -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-r'
        }

        It 'Tests yara stderr output handling' {
            Setup-CapturingCommandMock -CommandName 'yara' -OnInvoke {
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }

            $result = Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Tests yara catch block error handling' {
            Set-TestCommandThrowingMock -CommandName 'yara' -Message 'yara not found'

            { Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction Stop } | Should -Throw
        }

        It 'Tests yara Write-Error message format' {
            Set-TestCommandThrowingMock -CommandName 'yara' -Message 'yara not found'

            { Invoke-YaraScan -FilePath $script:TestFile -RulesPath $script:TestRulesPath -ErrorAction Stop } | Should -Throw '*yara*'
        }
    }
}
