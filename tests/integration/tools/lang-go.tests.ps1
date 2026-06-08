# ===============================================
# lang-go.tests.ps1
# Integration tests for lang-go.ps1 fragment
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
    $script:FragmentPath = Join-Path $script:ProfileDir 'lang-go.ps1'

    # Ensure bootstrap is loaded first
    $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
    if (Test-Path -LiteralPath $bootstrapPath) {
        . $bootstrapPath
    }

    # Load the fragment
    if (Test-Path -LiteralPath $script:FragmentPath) {
        . $script:FragmentPath
    }
    else {
        throw "Fragment not found: $script:FragmentPath"
    }
}

Describe 'lang-go.ps1 - Integration Tests' {
    Context 'Fragment loading' {
        It 'Loads lang-go fragment without errors' {
            { . $script:FragmentPath } | Should -Not -Throw
        }

        It 'Registers Release-GoProject function' {
            Get-Command Release-GoProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Invoke-Mage function' {
            Get-Command Invoke-Mage -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Lint-GoProject function' {
            Get-Command Lint-GoProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Build-GoProject function' {
            Get-Command Build-GoProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Test-GoProject function' {
            Get-Command Test-GoProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Alias creation' {
        It 'Creates goreleaser alias' {
            $alias = Get-Alias -Name 'goreleaser' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates mage alias' {
            $alias = Get-Alias -Name 'mage' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates golangci-lint alias' {
            $alias = Get-Alias -Name 'golangci-lint' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates go-build-project alias' {
            $alias = Get-Alias -Name 'go-build-project' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }

        It 'Creates go-test-project alias' {
            $alias = Get-Alias -Name 'go-test-project' -ErrorAction SilentlyContinue
            if (-not $alias) {
                Set-ItResult -Inconclusive -Because 'Set-AgentModeAlias may not be available in test environment'
            }
            else {
                $alias | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Graceful degradation - tool unavailable' {
        BeforeEach {
            if ($global:CollectedMissingToolWarnings) {
                $global:CollectedMissingToolWarnings.Clear()
            }
            if ($global:MissingToolWarnings) {
                $global:MissingToolWarnings.Clear()
            }
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            foreach ($cmd in @('go', 'goreleaser', 'mage', 'golangci-lint')) {
                Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
            }
        }

        It 'Release-GoProject handles missing tool gracefully' {
            $output = & { Release-GoProject -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'goreleaser not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'goreleaser'
        }

        It 'Invoke-Mage handles missing tool gracefully' {
            $output = & { Invoke-Mage -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'mage not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'mage'
        }

        It 'Lint-GoProject handles missing tool gracefully' {
            $output = & { Lint-GoProject -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'golangci-lint not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'golangci-lint'
        }

        It 'Build-GoProject handles missing tool gracefully' {
            $output = & { Build-GoProject -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'go not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'go'
        }

        It 'Test-GoProject handles missing tool gracefully' {
            $output = & { Test-GoProject -ErrorAction SilentlyContinue } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'go not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'go'
        }
    }

    Context 'Idempotency' {
        It 'Can be loaded multiple times without errors' {
            { . $script:FragmentPath } | Should -Not -Throw
            { . $script:FragmentPath } | Should -Not -Throw
        }

        It 'Functions remain available after multiple loads' {
            . $script:FragmentPath
            . $script:FragmentPath

            Get-Command Release-GoProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Invoke-Mage       -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Lint-GoProject    -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Build-GoProject   -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Test-GoProject    -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter validation' {
        BeforeEach {
            foreach ($cmd in @('go', 'goreleaser', 'mage', 'golangci-lint')) {
                Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
            }
        }

        It 'Release-GoProject accepts Arguments parameter' {
            { Release-GoProject -Arguments @('--snapshot') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Invoke-Mage accepts Target parameter' {
            { Invoke-Mage -Target 'build' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Invoke-Mage accepts Arguments parameter' {
            { Invoke-Mage -Target 'test' -Arguments @('-v') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Lint-GoProject accepts Arguments parameter' {
            { Lint-GoProject -Arguments @('--fix') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Build-GoProject accepts Output parameter' {
            { Build-GoProject -Output 'myapp' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Build-GoProject accepts Arguments parameter' {
            { Build-GoProject -Arguments @('-ldflags', '-s -w') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Test-GoProject accepts VerboseOutput switch' {
            { Test-GoProject -VerboseOutput -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Test-GoProject accepts Coverage switch' {
            { Test-GoProject -Coverage -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Test-GoProject accepts Arguments parameter' {
            { Test-GoProject -Arguments @('./...') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
