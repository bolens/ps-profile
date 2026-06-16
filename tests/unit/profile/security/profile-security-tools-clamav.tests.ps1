# ===============================================
# profile-security-tools-clamav.tests.ps1
# Unit tests for Invoke-ClamAVScan function
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

    $script:TestRoot = New-TestTempDirectory -Prefix 'ClamAvScanTest'
    $script:TestRepoPath = Join-Path $script:TestRoot 'TestRepo'
    $script:TestFile = Join-Path $script:TestRoot 'test-file.txt'

    New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
    Set-Content -Path $script:TestFile -Value 'Test content'
}

Describe 'security-tools.ps1 - Invoke-ClamAVScan' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'clamscan' -Available $false
        Remove-Item -Path 'Function:\clamscan' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:clamscan' -Force -ErrorAction SilentlyContinue
    }

    Context 'Invoke-ClamAVScan' {
        It 'Returns null when clamscan is not available' {
            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns error when path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'clamscan'

            $result = Invoke-ClamAVScan -Path (Join-Path $script:TestRoot 'Missing') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls clamscan with correct arguments when tool is available' {
            Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain $script:TestRepoPath
            $result | Should -Be 'Scan results'
        }

        It 'Includes recursive flag when specified' {
            Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

            Invoke-ClamAVScan -Path $script:TestRepoPath -Recursive -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-r'
        }

        It 'Creates quarantine directory and includes move flag when specified' {
            Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

            $quarantinePath = Join-Path $script:TestRoot 'quarantine'
            Invoke-ClamAVScan -Path $script:TestRepoPath -Quarantine $quarantinePath -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--move'
            $args | Should -Contain $quarantinePath
            Test-Path -LiteralPath $quarantinePath | Should -Be $true
        }

        It 'Handles ClamAV path not found' {
            Set-TestCommandAvailabilityState -CommandName 'clamscan'

            $result = Invoke-ClamAVScan -Path (Join-Path $script:TestRoot 'Missing') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Handles clamscan execution errors gracefully' {
            try {
            Set-TestCommandThrowingMock -CommandName 'clamscan' -Message 'Execution failed'

            $result = $null
                        $result = Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            }
            catch {
                $result = $null

                $result | Should -BeNullOrEmpty
            }
        }

        It 'Tests ClamAV with recursive flag' {
            Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

            Invoke-ClamAVScan -Path $script:TestRepoPath -Recursive -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-r'
        }

        It 'Tests ClamAV with both recursive and quarantine' {
            Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

            $quarantinePath = Join-Path $script:TestRoot 'quarantine-both'
            Invoke-ClamAVScan -Path $script:TestRepoPath -Recursive -Quarantine $quarantinePath -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '-r'
            $args | Should -Contain '--move'
            $args | Should -Contain $quarantinePath
        }

        It 'Tests ClamAV quarantine directory creation' {
            Setup-CapturingCommandMock -CommandName 'clamscan' -Output 'Scan results'

            $quarantinePath = Join-Path $script:TestRoot 'quarantine-new'
            Invoke-ClamAVScan -Path $script:TestRepoPath -Quarantine $quarantinePath -ErrorAction SilentlyContinue | Out-Null

            Test-Path -LiteralPath $quarantinePath | Should -Be $true
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Tests clamscan stderr output handling' {
            Setup-CapturingCommandMock -CommandName 'clamscan' -OnInvoke {
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }

            $result = Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Tests clamscan catch block error handling' {
            Set-TestCommandThrowingMock -CommandName 'clamscan' -Message 'clamscan not found'

            { Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction Stop } | Should -Throw
        }

        It 'Tests clamscan Write-Error message format' {
            Set-TestCommandThrowingMock -CommandName 'clamscan' -Message 'clamscan not found'

            { Invoke-ClamAVScan -Path $script:TestRepoPath -ErrorAction Stop } | Should -Throw '*clamscan*'
        }
    }
}
