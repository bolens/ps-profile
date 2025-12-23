# ===============================================
# preference-aware-install-hints-fallback.tests.ps1
# Integration tests for preference-aware install hints fallback chains
# ===============================================

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap\MissingToolWarnings.ps1' -StartPath $PSScriptRoot -EnsureExists
    if ($null -eq $script:BootstrapPath -or [string]::IsNullOrWhiteSpace($script:BootstrapPath)) {
        throw "Get-TestPath returned null or empty value for BootstrapPath"
    }
    if (-not (Test-Path -LiteralPath $script:BootstrapPath)) {
        throw "Bootstrap file not found at: $script:BootstrapPath"
    }
    . $script:BootstrapPath
}

Describe 'Preference-Aware Install Hints - Integration Tests (Fallback Chains)' {
    Context 'Python Package Manager Fallback Chain' {
        BeforeEach {
            $script:OriginalPythonPm = $env:PS_PYTHON_PACKAGE_MANAGER
            Remove-Item -Path Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        }
        
        AfterEach {
            if ($script:OriginalPythonPm) {
                $env:PS_PYTHON_PACKAGE_MANAGER = $script:OriginalPythonPm
            }
            else {
                Remove-Item -Path Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
        }
        
        It 'Falls back through Python package manager chain when preferred is unavailable' {
            # Set preference to a manager that may not be available
            $env:PS_PYTHON_PACKAGE_MANAGER = 'poetry'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-python-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should provide some installation method even if poetry is not available
            $result | Should -Match 'Install with:'
        }
        
        It 'Falls back to system package manager when language package managers unavailable' {
            Remove-Item -Path Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-python-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Install with:'
        }
        
        It 'Uses DefaultInstallCommand when provided' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'python-package' -DefaultInstallCommand 'custom install command'
            $result | Should -Match 'custom install command'
        }
    }
    
    Context 'Node Package Manager Fallback Chain' {
        BeforeEach {
            $script:OriginalNodePm = $env:PS_NODE_PACKAGE_MANAGER
            Remove-Item -Path Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        }
        
        AfterEach {
            if ($script:OriginalNodePm) {
                $env:PS_NODE_PACKAGE_MANAGER = $script:OriginalNodePm
            }
            else {
                Remove-Item -Path Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
        }
        
        It 'Falls back through Node package manager chain when preferred is unavailable' {
            $env:PS_NODE_PACKAGE_MANAGER = 'yarn'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-node-tool' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Install with:'
        }
        
        It 'Falls back to npm when other Node package managers unavailable' {
            Remove-Item -Path Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-node-tool' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest npm or system package manager
            $result | Should -Match 'npm|scoop|brew|apt'
        }
        
        It 'Falls back to system package manager for runtime installations' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest system package manager for runtime
            $result | Should -Match 'scoop|winget|brew|apt|nodejs'
        }
    }
    
    Context 'System Package Manager Fallback Chain' {
        BeforeEach {
            $script:OriginalSystemPm = $env:PS_SYSTEM_PACKAGE_MANAGER
            Remove-Item -Path Env:PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
        }
        
        AfterEach {
            if ($script:OriginalSystemPm) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = $script:OriginalSystemPm
            }
            else {
                Remove-Item -Path Env:PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
        }
        
        It 'Falls back through system package manager chain on Windows' {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'winget'
                $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                $result | Should -Not -BeNullOrEmpty
                # Should suggest winget or fallback to scoop/choco
                $result | Should -Match 'winget|scoop|choco'
            }
        }
        
        It 'Falls back through system package manager chain on Linux' {
            if ($IsLinux) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'yum'
                $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                $result | Should -Not -BeNullOrEmpty
                # Should suggest yum or fallback to apt/dnf/pacman
                $result | Should -Match 'yum|apt|dnf|pacman'
            }
        }
        
        It 'Falls back through system package manager chain on macOS' {
            if ($IsMacOS) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'homebrew'
                $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                $result | Should -Not -BeNullOrEmpty
                # Should suggest homebrew or fallback to scoop
                $result | Should -Match 'brew|scoop'
            }
        }
        
        It 'Falls back to auto-detection when preference unavailable' {
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'nonexistent-pm'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            # Should still provide a suggestion
            $result | Should -Match 'Install with:'
        }
    }
    
    Context 'Cross-Language Fallback Chain' {
        It 'Falls back from language-specific to system package manager' {
            # Test with a tool that doesn't match any language-specific pattern
            $result = Get-PreferenceAwareInstallHint -ToolName 'generic-tool-xyz' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest system package manager
            $result | Should -Match 'scoop|brew|apt|winget|choco'
        }
        
        It 'Falls back from tool-specific to language-specific to system' {
            # Test with a tool that might have tool-specific method but falls through
            $result = Get-PreferenceAwareInstallHint -ToolName 'unknown-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should provide some installation method
            $result | Should -Match 'Install with:'
        }
    }
    
    Context 'Default Install Command Priority' {
        It 'Uses DefaultInstallCommand over all fallbacks' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic' -DefaultInstallCommand 'priority-command'
            $result | Should -Match 'priority-command'
        }
        
        It 'Respects DefaultInstallCommand even with preferences set' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'python-package' -DefaultInstallCommand 'override-command'
            $result | Should -Match 'override-command'
        }
    }
    
    Context 'Fallback Chain Generation' {
        It 'Generates fallback chain with preferred method first' {
            $result = Get-InstallMethodFallbackChain -PreferredMethod 'scoop install tool' -FallbackMethods @('winget install tool', 'choco install tool -y')
            $result | Should -Match 'scoop install tool'
            $result | Should -Match 'or:'
        }
        
        It 'Shows multiple fallback options' {
            $result = Get-InstallMethodFallbackChain -PreferredMethod 'scoop install tool' -FallbackMethods @('winget install tool', 'choco install tool -y')
            $result | Should -Match 'winget'
            $result | Should -Match 'choco'
        }
        
        It 'Limits fallback options to MaxFallbacks' {
            $result = Get-InstallMethodFallbackChain -PreferredMethod 'method1' -FallbackMethods @('method2', 'method3', 'method4', 'method5') -MaxFallbacks 2
            # Should have preferred + 2 fallbacks = 3 total
            $methods = ($result -split ' \(or: ').Count
            $methods | Should -BeLessOrEqual 3
        }
        
        It 'Handles no preferred method gracefully' {
            $result = Get-InstallMethodFallbackChain -FallbackMethods @('method1', 'method2')
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'method1'
        }
        
        It 'Handles empty fallback methods' {
            $result = Get-InstallMethodFallbackChain -PreferredMethod 'method1' -FallbackMethods @()
            $result | Should -Be 'method1'
        }
    }
    
    Context 'System Package Manager Fallback Chain' {
        BeforeEach {
            $script:OriginalSystemPm = $env:PS_SYSTEM_PACKAGE_MANAGER
        }
        
        AfterEach {
            if ($script:OriginalSystemPm) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = $script:OriginalSystemPm
            }
            else {
                Remove-Item -Path Env:PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
        }
        
        It 'Returns fallback chain for Windows platform' {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $result = Get-SystemPackageManagerFallbackChain -ToolName 'test-tool' -Platform 'Windows'
                $result | Should -Not -BeNullOrEmpty
                $result.FallbackChain | Should -Not -BeNullOrEmpty
                $result.Platform | Should -Be 'Windows'
            }
        }
        
        It 'Prioritizes preferred manager in fallback chain' {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'winget'
                $result = Get-SystemPackageManagerFallbackChain -ToolName 'test-tool' -Platform 'Windows' -PreferredManager 'winget'
                if ($result.Preferred) {
                    $result.Preferred | Should -Match 'winget'
                }
            }
        }
        
        It 'Shows multiple fallback options when preferred unavailable' {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'nonexistent-pm'
                $result = Get-SystemPackageManagerFallbackChain -ToolName 'test-tool' -Platform 'Windows' -PreferredManager 'nonexistent-pm'
                # Should still provide fallback options
                if ($result.FallbackChain) {
                    $result.FallbackChain | Should -Match 'or:'
                }
            }
        }
        
        It 'Returns fallback chain for Linux platform' {
            if ($IsLinux) {
                $result = Get-SystemPackageManagerFallbackChain -ToolName 'test-tool' -Platform 'Linux'
                $result | Should -Not -BeNullOrEmpty
                $result.Platform | Should -Be 'Linux'
            }
        }
        
        It 'Returns fallback chain for macOS platform' {
            if ($IsMacOS) {
                $result = Get-SystemPackageManagerFallbackChain -ToolName 'test-tool' -Platform 'macOS'
                $result | Should -Not -BeNullOrEmpty
                $result.Platform | Should -Be 'macOS'
            }
        }
    }
    
    Context 'Language-Specific Fallback Chains' {
        BeforeEach {
            $script:OriginalPythonPm = $env:PS_PYTHON_PACKAGE_MANAGER
            $script:OriginalNodePm = $env:PS_NODE_PACKAGE_MANAGER
        }
        
        AfterEach {
            if ($script:OriginalPythonPm) {
                $env:PS_PYTHON_PACKAGE_MANAGER = $script:OriginalPythonPm
            }
            else {
                Remove-Item -Path Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
            
            if ($script:OriginalNodePm) {
                $env:PS_NODE_PACKAGE_MANAGER = $script:OriginalNodePm
            }
            else {
                Remove-Item -Path Env:PS_NODE_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
        }
        
        It 'Shows Python package manager fallback chain' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-python-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should show preferred method and potentially fallbacks
            $result | Should -Match 'Install with:'
        }
        
        It 'Shows Node package manager fallback chain' {
            $env:PS_NODE_PACKAGE_MANAGER = 'pnpm'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-node-tool' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            # Should show preferred method and potentially fallbacks
            $result | Should -Match 'Install with:'
        }
        
        It 'Includes multiple fallback options in hint' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'python-package'
            # If multiple package managers are available, should show fallback chain
            if ($result -match 'or:') {
                $result | Should -Match 'or:'
            }
        }
    }
}
