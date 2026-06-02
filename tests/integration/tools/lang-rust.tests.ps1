# ===============================================
# lang-rust.tests.ps1
# Integration tests for lang-rust-*.ps1 fragments
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:FragmentPaths = @(
        (Join-Path $script:ProfileDir 'lang-rust-tools.ps1'),
        (Join-Path $script:ProfileDir 'lang-rust-build.ps1'),
        (Join-Path $script:ProfileDir 'lang-rust-audit.ps1')
    )

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    foreach ($fragmentPath in $script:FragmentPaths) {
        if (-not (Test-Path -LiteralPath $fragmentPath)) {
            throw "Fragment not found: $fragmentPath"
        }
        . $fragmentPath
    }
}

Describe 'lang-rust Integration Tests' {
    Context 'Function Registration' {
        It 'Registers Install-RustBinary function' {
            Get-Command Install-RustBinary -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Watch-RustProject function' {
            Get-Command Watch-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Audit-RustProject function' {
            Get-Command Audit-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Test-RustOutdated function' {
            Get-Command Test-RustOutdated -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Build-RustRelease function' {
            Get-Command Build-RustRelease -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Update-RustDependencies function' {
            Get-Command Update-RustDependencies -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Registers Clear-CargoCache function' {
            Get-Command Clear-CargoCache -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Alias Creation' {
        It 'Creates cargo-binstall alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-binstall -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-binstall' -Target 'Install-RustBinary' | Out-Null
                }
                $alias = Get-Alias cargo-binstall -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates cargo-watch alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-watch -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-watch' -Target 'Watch-RustProject' | Out-Null
                }
                $alias = Get-Alias cargo-watch -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates cargo-audit alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-audit -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-audit' -Target 'Audit-RustProject' | Out-Null
                }
                $alias = Get-Alias cargo-audit -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates cargo-outdated alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-outdated -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-outdated' -Target 'Test-RustOutdated' | Out-Null
                }
                $alias = Get-Alias cargo-outdated -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates cargo-build-release alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-build-release -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-build-release' -Target 'Build-RustRelease' | Out-Null
                }
                $alias = Get-Alias cargo-build-release -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates cargo-update-deps alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-update-deps -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-update-deps' -Target 'Update-RustDependencies' | Out-Null
                }
                $alias = Get-Alias cargo-update-deps -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates cargo-cleanup alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-cleanup -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-cleanup' -Target 'Clear-CargoCache' | Out-Null
                }
                $alias = Get-Alias cargo-cleanup -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }

        It 'Creates cargo-clean alias' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath -ErrorAction SilentlyContinue
            }
            $alias = Get-Alias cargo-clean -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'cargo-clean' -Target 'Clear-CargoCache' | Out-Null
                }
                $alias = Get-Alias cargo-clean -ErrorAction SilentlyContinue
            }
            $alias | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Graceful Degradation' {
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
        }

        It 'Install-RustBinary handles missing cargo-binstall gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-binstall' -Available $false
            $output = & { Install-RustBinary -Packages @('test-package') } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cargo-binstall not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cargo-binstall'
        }

        It 'Watch-RustProject handles missing cargo-watch gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-watch' -Available $false
            $output = & { Watch-RustProject } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cargo-watch not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cargo-watch'
        }

        It 'Audit-RustProject handles missing cargo-audit gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-audit' -Available $false
            $output = & { Audit-RustProject } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cargo-audit not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cargo-audit'
        }

        It 'Test-RustOutdated handles missing cargo-outdated gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'cargo-outdated' -Available $false
            $output = & { Test-RustOutdated } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cargo-outdated not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cargo-outdated'
        }

        It 'Build-RustRelease handles missing cargo gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'cargo' -Available $false
            $output = & { Build-RustRelease } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cargo not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cargo'
        }

        It 'Update-RustDependencies handles missing cargo gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'cargo' -Available $false
            $output = & { Update-RustDependencies } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cargo not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cargo'
        }

        It 'Clear-CargoCache handles missing cargo gracefully' {
            Mock-CommandAvailabilityPester -CommandName 'cargo' -Available $false
            $output = & { Clear-CargoCache } 2>&1 3>&1 | Out-String
            Assert-TestMissingToolWarning -Output $output -Pattern 'cargo not found'
            Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'cargo'
        }
    }

    Context 'Clear-CargoCache Function Tests' {
        BeforeAll {
            Mock-CommandAvailabilityPester -CommandName 'cargo' -Available $true
            Mock-CommandAvailabilityPester -CommandName 'cargo-cache' -Available $true
        }

        It 'Clear-CargoCache calls cargo-cache with --autoclean by default' {
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-cache' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cache cleaned successfully'
            }

            Clear-CargoCache -ErrorAction SilentlyContinue 4>&1 | Out-Null
            Should -Invoke -CommandName 'cargo-cache' -Times 1 -Exactly

            if ($script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'cache'
                $script:capturedArgs | Should -Contain '--autoclean'
            }
        }

        It 'Clear-CargoCache with Autoclean passes --autoclean flag' {
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-cache' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'Cache cleaned successfully'
            }

            Clear-CargoCache -Autoclean -ErrorAction SilentlyContinue 4>&1 | Out-Null
            Should -Invoke -CommandName 'cargo-cache' -Times 1 -Exactly

            if ($script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'cache'
                $script:capturedArgs | Should -Contain '--autoclean'
            }
        }

        It 'Clear-CargoCache with All passes --remove-dir all' {
            $script:capturedArgs = $null
            Mock -CommandName 'cargo-cache' -MockWith {
                param([Parameter(ValueFromRemainingArguments = $true)][object[]]$Arguments)
                $script:capturedArgs = $Arguments
                Write-Output 'All cache removed successfully'
            }

            Clear-CargoCache -All -ErrorAction SilentlyContinue 4>&1 | Out-Null
            Should -Invoke -CommandName 'cargo-cache' -Times 1 -Exactly

            if ($script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'cache'
                $script:capturedArgs | Should -Contain '--remove-dir'
                $script:capturedArgs | Should -Contain 'all'
            }
        }
    }

    Context 'Fragment Loading' {
        It 'Fragment can be loaded multiple times (idempotency)' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                { . $fragmentPath } | Should -Not -Throw
                { . $fragmentPath } | Should -Not -Throw
                { . $fragmentPath } | Should -Not -Throw
            }
        }

        It 'Functions remain available after multiple loads' {
            foreach ($fragmentPath in $script:FragmentPaths) {
                . $fragmentPath
                . $fragmentPath
                . $fragmentPath
            }

            Get-Command Install-RustBinary -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Watch-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Audit-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
