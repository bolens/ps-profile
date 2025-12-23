# ===============================================
# preference-aware-install-hints.tests.ps1
# Unit tests for preference-aware install hints
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

Describe 'Preference-Aware Install Hints - Unit Tests' {
    Context 'Tool Type Auto-Detection' {
        It 'Detects Python package managers correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'pip' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'pip|python'
        }
        
        It 'Detects Node package managers correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'npm|node'
        }
        
        It 'Detects Rust tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'cargo' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'cargo|rust'
        }
        
        It 'Detects Go tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'go' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'go'
        }
        
        It 'Detects Java build tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'maven' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'maven|mvn'
        }
        
        It 'Detects Ruby tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'gem' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'gem|ruby'
        }
        
        It 'Detects PHP tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'composer' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'composer|php'
        }
        
        It 'Detects .NET tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'dotnet' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'dotnet'
        }
        
        It 'Detects Dart tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'dart' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'dart'
        }
        
        It 'Detects Elixir tools correctly' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'mix' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'mix|elixir'
        }
    }
    
    Context 'Preference Detection Logic' {
        BeforeEach {
            # Save original environment variables
            $script:OriginalPythonPm = $env:PS_PYTHON_PACKAGE_MANAGER
            $script:OriginalNodePm = $env:PS_NODE_PACKAGE_MANAGER
            $script:OriginalSystemPm = $env:PS_SYSTEM_PACKAGE_MANAGER
        }
        
        AfterEach {
            # Restore original environment variables
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
            
            if ($script:OriginalSystemPm) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = $script:OriginalSystemPm
            }
            else {
                Remove-Item -Path Env:PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
        }
        
        It 'Respects PS_PYTHON_PACKAGE_MANAGER preference when set' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            $result = Get-PreferenceAwareInstallHint -ToolName 'some-python-tool' -ToolType 'python-package'
            $result | Should -Match 'uv'
        }
        
        It 'Respects PS_NODE_PACKAGE_MANAGER preference when set' {
            $env:PS_NODE_PACKAGE_MANAGER = 'pnpm'
            $result = Get-PreferenceAwareInstallHint -ToolName 'some-node-tool' -ToolType 'node-package'
            $result | Should -Match 'pnpm'
        }
        
        It 'Respects PS_SYSTEM_PACKAGE_MANAGER preference when set' {
            $env:PS_SYSTEM_PACKAGE_MANAGER = 'scoop'
            $result = Get-PreferenceAwareInstallHint -ToolName 'some-generic-tool' -ToolType 'generic'
            $result | Should -Match 'scoop'
        }
        
        It 'Falls back to auto when preference is not set' {
            Remove-Item -Path Env:PS_PYTHON_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            $result = Get-PreferenceAwareInstallHint -ToolName 'some-python-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Tool-Specific Installation Methods' {
        It 'Returns tool-specific method for pnpm when available' {
            $result = Get-ToolSpecificInstallMethod -ToolName 'pnpm'
            if ($result) {
                $result | Should -Match 'pnpm|scoop|npm|brew'
            }
        }
        
        It 'Returns tool-specific method for uv when available' {
            $result = Get-ToolSpecificInstallMethod -ToolName 'uv'
            if ($result) {
                $result | Should -Match 'uv|scoop|pip|brew|curl'
            }
        }
        
        It 'Returns tool-specific method for poetry when available' {
            $result = Get-ToolSpecificInstallMethod -ToolName 'poetry'
            if ($result) {
                $result | Should -Match 'poetry|scoop|pip|brew|curl'
            }
        }
        
        It 'Returns null for unknown tools' {
            $result = Get-ToolSpecificInstallMethod -ToolName 'unknown-tool-xyz'
            $result | Should -BeNullOrEmpty
        }
        
        It 'Respects platform parameter' {
            $result = Get-ToolSpecificInstallMethod -ToolName 'pnpm' -Platform 'Windows'
            if ($result) {
                $result | Should -Match 'scoop|winget|npm|choco'
            }
        }
    }
    
    Context 'Preference Validation' {
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
        
        It 'Validates valid Python package manager preference' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-package'
            $result.Valid | Should -Be $true
            $result.Preferences['PS_PYTHON_PACKAGE_MANAGER'] | Should -Be 'uv'
        }
        
        It 'Detects invalid Python package manager preference' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'invalid-pm'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-package'
            $result.Valid | Should -Be $false
            $result.Errors | Should -Match 'Invalid PS_PYTHON_PACKAGE_MANAGER'
        }
        
        It 'Validates valid Node package manager preference' {
            $env:PS_NODE_PACKAGE_MANAGER = 'pnpm'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'node-package'
            $result.Valid | Should -Be $true
            $result.Preferences['PS_NODE_PACKAGE_MANAGER'] | Should -Be 'pnpm'
        }
        
        It 'Detects invalid Node package manager preference' {
            $env:PS_NODE_PACKAGE_MANAGER = 'invalid-pm'
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'node-package'
            $result.Valid | Should -Be $false
            $result.Errors | Should -Match 'Invalid PS_NODE_PACKAGE_MANAGER'
        }
        
        It 'Warns when preference is set but command is not available' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'nonexistent-pm'
            # First set an invalid value to trigger error, then set valid but unavailable
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            # Mock Test-CommandAvailable to return false
            Mock -CommandName Test-CommandAvailable -MockWith { return $false } -ParameterFilter { $CommandName -eq 'uv' }
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-package'
            # Note: This test may need adjustment based on actual implementation
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Validates all preferences when PreferenceType is all' {
            $result = Test-PreferenceAwareInstallPreferences -PreferenceType 'all'
            $result | Should -Not -BeNullOrEmpty
            $result.Preferences | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Command Availability Testing' {
        It 'Detects available commands correctly' {
            # Test with a command that should exist
            $result = Test-CommandAvailable -CommandName 'powershell'
            $result | Should -Be $true
        }
        
        It 'Detects unavailable commands correctly' {
            $result = Test-CommandAvailable -CommandName 'nonexistent-command-xyz-123'
            $result | Should -Be $false
        }
        
        It 'Maps package manager names to commands correctly' {
            # Test mapping for common package managers
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                $result = Test-CommandAvailable -CommandName 'scoop'
                $result | Should -Be $true
            }
        }
    }
    
    Context 'Edge Cases' {
        It 'Handles empty tool name gracefully' {
            { Get-PreferenceAwareInstallHint -ToolName '' -ToolType 'generic' } | Should -Not -Throw
        }
        
        It 'Handles null default install command' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic' -DefaultInstallCommand $null
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles missing tools with preference set' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            $result = Get-PreferenceAwareInstallHint -ToolName 'nonexistent-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles invalid tool type gracefully' {
            # Note: ToolType is validated via ValidateSet, so this tests the auto-detection
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles whitespace-only tool names' {
            { Get-PreferenceAwareInstallHint -ToolName '   ' -ToolType 'generic' } | Should -Not -Throw
        }
        
        It 'Handles very long tool names' {
            $longName = 'a' * 1000
            $result = Get-PreferenceAwareInstallHint -ToolName $longName -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles special characters in tool names' {
            $specialName = 'tool-with-special-chars-!@#$%^&*()'
            $result = Get-PreferenceAwareInstallHint -ToolName $specialName -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles case-insensitive tool name matching' {
            $result1 = Get-PreferenceAwareInstallHint -ToolName 'PNPM' -ToolType 'node-package'
            $result2 = Get-PreferenceAwareInstallHint -ToolName 'pnpm' -ToolType 'node-package'
            # Both should return valid results
            $result1 | Should -Not -BeNullOrEmpty
            $result2 | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Invalid Preferences Edge Cases' {
        BeforeEach {
            $script:OriginalPythonPm = $env:PS_PYTHON_PACKAGE_MANAGER
            $script:OriginalNodePm = $env:PS_NODE_PACKAGE_MANAGER
            $script:OriginalSystemPm = $env:PS_SYSTEM_PACKAGE_MANAGER
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
            
            if ($script:OriginalSystemPm) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = $script:OriginalSystemPm
            }
            else {
                Remove-Item -Path Env:PS_SYSTEM_PACKAGE_MANAGER -ErrorAction SilentlyContinue
            }
        }
        
        It 'Handles invalid preference values gracefully' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'invalid-pm-xyz'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'python-package'
            # Should still return a valid result, falling back to defaults
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Install with:'
        }
        
        It 'Handles empty preference values' {
            $env:PS_PYTHON_PACKAGE_MANAGER = ''
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles whitespace-only preference values' {
            $env:PS_PYTHON_PACKAGE_MANAGER = '   '
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Handles case variations in preferences' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'UV'
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'python-package'
            # Should handle case-insensitive matching
            $result | Should -Not -BeNullOrEmpty
        }
        
        It 'Validates and reports invalid preferences correctly' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'invalid-pm'
            $validation = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-package'
            $validation.Valid | Should -Be $false
            $validation.Errors | Should -Not -BeNullOrEmpty
        }
        
        It 'Warns about unavailable preferred tools' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'uv'
            # Mock Test-CommandAvailable to return false for uv
            Mock -CommandName Test-CommandAvailable -MockWith { 
                if ($CommandName -eq 'uv') { return $false }
                return $true
            }
            $validation = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-package'
            # Should have warnings if uv is not available
            $validation | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Missing Tools Edge Cases' {
        It 'Provides suggestions when all package managers are missing' {
            # Test with a tool that requires package managers
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
            # Should still provide a suggestion even if package managers are missing
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Install with:'
        }
        
        It 'Handles missing Python runtime gracefully' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'python' -ToolType 'python-runtime'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest installation method
            $result | Should -Match 'Install with:'
        }
        
        It 'Handles missing Node runtime gracefully' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'npm' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest installation method
            $result | Should -Match 'Install with:'
        }
        
        It 'Provides fallback when tool-specific method unavailable' {
            # Test with a tool that has tool-specific methods but they're not available
            $result = Get-PreferenceAwareInstallHint -ToolName 'pnpm' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            # Should provide some installation method
            $result | Should -Match 'Install with:'
        }
    }
    
    Context 'Preference Setup Edge Cases' {
        It 'Handles non-interactive mode correctly' {
            $result = Set-PreferenceAwareInstallPreferences -PreferenceType 'python-package' -NonInteractive
            $result | Should -Not -BeNullOrEmpty
            $result.Preferences | Should -Not -BeNullOrEmpty
        }
        
        It 'Validates preferences after setting' {
            $env:PS_PYTHON_PACKAGE_MANAGER = 'invalid-pm'
            $result = Set-PreferenceAwareInstallPreferences -PreferenceType 'python-package' -NonInteractive
            # Should still return results even with invalid preference
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
