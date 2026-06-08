# ===============================================
# profile-security-tools-osv.tests.ps1
# Unit tests for Invoke-OSVScan function
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

    $script:TestRoot = New-TestTempDirectory -Prefix 'OsvScanTest'
    $script:TestRepoPath = Join-Path $script:TestRoot 'TestRepo'
    $script:TestFile = Join-Path $script:TestRoot 'test-file.txt'

    New-Item -ItemType Directory -Path $script:TestRepoPath -Force | Out-Null
    Set-Content -Path $script:TestFile -Value 'Test content'
}

Describe 'security-tools.ps1 - Invoke-OSVScan' {
    BeforeEach {
        Clear-TestCommandInvocationCapture

        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Set-TestCommandAvailabilityState -CommandName 'osv-scanner' -Available $false
        Remove-Item -Path 'Function:\osv-scanner' -Force -ErrorAction SilentlyContinue
        Remove-Item -Path 'Function:\global:osv-scanner' -Force -ErrorAction SilentlyContinue
    }

    Context 'Invoke-OSVScan' {
        It 'Returns null when osv-scanner is not available' {
            $result = Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Returns error when path does not exist' {
            Set-TestCommandAvailabilityState -CommandName 'osv-scanner'

            $result = Invoke-OSVScan -Path (Join-Path $script:TestRoot 'Missing') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Calls osv-scanner with correct arguments when tool is available' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -Output 'Scan results'

            $result = Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat 'json' -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 1
            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--format'
            $args | Should -Contain 'json'
            $args | Should -Contain $script:TestRepoPath
            $result | Should -Be 'Scan results'
        }

        It 'Uses default path and format when not specified' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -Output 'Scan results'

            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-OSVScan -ErrorAction SilentlyContinue
                $result | Should -Not -BeNullOrEmpty
                $args = Get-TestCommandInvocationArgsFlat
                $args | Should -Contain '--format'
                $args | Should -Contain 'table'
            }
            finally {
                Pop-Location
            }
        }

        It 'Supports different output formats' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -Output 'Scan results'

            foreach ($format in @('json', 'table')) {
                Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat $format -ErrorAction SilentlyContinue | Out-Null
            }

            $global:TestCommandInvocationCaptures.Count | Should -Be 2
            foreach ($capture in $global:TestCommandInvocationCaptures) {
                $argsStrings = @($capture | ForEach-Object { $_.ToString() })
                $argsStrings | Should -Contain '--format'
            }
        }

        It 'Handles osv-scanner execution errors gracefully' {
            Set-TestCommandThrowingMock -CommandName 'osv-scanner' -Message 'Execution failed'

            $result = $null
            try {
                $result = Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue
            }
            catch {
                $result = $null
            }

            $result | Should -BeNullOrEmpty
        }

        It 'Validates OutputFormat parameter' {
            Set-TestCommandAvailabilityState -CommandName 'osv-scanner'

            { Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat 'invalid' -ErrorAction Stop } | Should -Throw
        }

        It 'Tests osv-scanner with json format' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -Output 'Scan results'

            Invoke-OSVScan -Path $script:TestRepoPath -OutputFormat 'json' -ErrorAction SilentlyContinue | Out-Null

            $args = Get-TestCommandInvocationArgsFlat
            $args | Should -Contain '--format'
            $args | Should -Contain 'json'
        }

        It 'Handles whitespace-only path' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -Output 'Scan results'

            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-OSVScan -Path '   ' -ErrorAction SilentlyContinue
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles osv-scanner path not found' {
            Set-TestCommandAvailabilityState -CommandName 'osv-scanner'

            $result = Invoke-OSVScan -Path (Join-Path $script:TestRoot 'Missing') -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
        }

        It 'Uses default path when osv-scanner path is null' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -Output 'Scan results'

            Push-Location $script:TestRepoPath
            try {
                $result = Invoke-OSVScan -Path $null -ErrorAction SilentlyContinue
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'Handles multiple pipeline inputs' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -Output 'Scan results'

            $paths = @($script:TestRepoPath, $script:TestFile)
            $null = $paths | Invoke-OSVScan -ErrorAction SilentlyContinue

            $global:TestCommandInvocationCaptures.Count | Should -Be 2
        }

        It 'Tests osv-scanner stderr output handling' {
            Setup-CapturingCommandMock -CommandName 'osv-scanner' -OnInvoke {
                [Console]::Error.WriteLine('Warning message')
                return 'Scan results'
            }

            $result = Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $global:TestCommandInvocationCaptures.Count | Should -Be 1
        }

        It 'Tests osv-scanner catch block error handling' {
            Set-TestCommandThrowingMock -CommandName 'osv-scanner' -Message 'osv-scanner not found'

            { Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction Stop } | Should -Throw
        }

        It 'Tests osv-scanner Write-Error message format' {
            Set-TestCommandThrowingMock -CommandName 'osv-scanner' -Message 'osv-scanner not found'

            { Invoke-OSVScan -Path $script:TestRepoPath -ErrorAction Stop } | Should -Throw '*osv-scanner*'
        }
    }
}
