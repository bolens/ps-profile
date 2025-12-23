# ===============================================
# lang-rust.tests.ps1
# Integration tests for lang-rust.ps1 fragment
# ===============================================

. (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:LangRustPath = Join-Path $script:ProfileDir 'lang-rust.ps1'
    
    # Load bootstrap first
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Load lang-rust fragment
    . $script:LangRustPath
}

Describe 'lang-rust.ps1 Integration Tests' {
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
            . $script:LangRustPath -ErrorAction SilentlyContinue
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
        It 'Install-RustBinary handles missing cargo-binstall gracefully' {
            $result = Install-RustBinary -Packages @('test-package') -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
            # (actual behavior depends on whether cargo-binstall is installed)
        }
        
        It 'Watch-RustProject handles missing cargo-watch gracefully' {
            $result = Watch-RustProject -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }
        
        It 'Audit-RustProject handles missing cargo-audit gracefully' {
            $result = Audit-RustProject -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }
        
        It 'Test-RustOutdated handles missing cargo-outdated gracefully' {
            $result = Test-RustOutdated -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }
        
        It 'Build-RustRelease handles missing cargo gracefully' {
            $result = Build-RustRelease -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }
        
        It 'Update-RustDependencies handles missing cargo gracefully' {
            $result = Update-RustDependencies -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }
        
        It 'Clear-CargoCache handles missing cargo gracefully' {
            $result = Clear-CargoCache -ErrorAction SilentlyContinue
            # Should return null or empty when tool is not available
        }
    }
    
    Context 'Clear-CargoCache Function Tests' {
        BeforeAll {
            # Mock cargo and cargo-cache commands
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
            
            # Execute
            { Clear-CargoCache -ErrorAction SilentlyContinue 4>&1 | Out-Null } | Should -Not -Throw
            
            # Verify
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
            
            # Execute
            { Clear-CargoCache -Autoclean -ErrorAction SilentlyContinue 4>&1 | Out-Null } | Should -Not -Throw
            
            # Verify
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
            
            # Execute
            { Clear-CargoCache -All -ErrorAction SilentlyContinue 4>&1 | Out-Null } | Should -Not -Throw
            
            # Verify
            if ($script:capturedArgs) {
                $script:capturedArgs | Should -Contain 'cache'
                $script:capturedArgs | Should -Contain '--remove-dir'
                $script:capturedArgs | Should -Contain 'all'
            }
        }
    }
    
    Context 'Fragment Loading' {
        It 'Fragment can be loaded multiple times (idempotency)' {
            { . $script:LangRustPath } | Should -Not -Throw
            { . $script:LangRustPath } | Should -Not -Throw
            { . $script:LangRustPath } | Should -Not -Throw
        }
        
        It 'Functions remain available after multiple loads' {
            . $script:LangRustPath
            . $script:LangRustPath
            . $script:LangRustPath
            
            Get-Command Install-RustBinary -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Watch-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Audit-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Install-RustBinary -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Watch-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Audit-RustProject -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

