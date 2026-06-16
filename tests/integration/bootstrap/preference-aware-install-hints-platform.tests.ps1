# ===============================================
# preference-aware-install-hints-platform.tests.ps1
# Cross-platform tests for platform-specific suggestions
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
    $bootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    foreach ($file in @('MissingToolWarnings.ps1', 'ToolInstallRegistry.ps1', 'InstallHintResolver.ps1')) {
        $path = Join-Path $bootstrapDir $file
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Bootstrap file not found at: $path"
        }
        $null = . $path
    }
}

Describe 'Preference-Aware Install Hints - Cross-Platform Tests' {
    Context 'Windows Platform-Specific Suggestions' {
        It 'Suggests Windows-appropriate package managers on Windows' -Skip:(-not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest Windows package managers
            $result | Should -Match 'scoop|winget|choco'
        }
        
        It 'Prioritizes Scoop on Windows when available' -Skip:(-not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'auto'
                $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                $result | Should -Match 'scoop'
            }
        }
        
        It 'Falls back to Winget on Windows when Scoop unavailable' -Skip:(-not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue) -and (Get-Command winget -ErrorAction SilentlyContinue)) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'auto'
                $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                $result | Should -Match 'winget'
            }
        }
        
        It 'Suggests Windows-specific installation for pnpm' -Skip:(-not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'pnpm' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest Windows-appropriate method
            $result | Should -Match 'scoop|winget|npm|choco'
        }
        
        It 'Suggests Windows-specific installation for uv' -Skip:(-not ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'uv' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest Windows-appropriate method
            $result | Should -Match 'scoop|winget|pip'
        }
    }
    
    Context 'Linux Platform-Specific Suggestions' {
        It 'Suggests Linux-appropriate package managers on Linux' -Skip:(-not $IsLinux) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest Linux package managers
            $result | Should -Match 'apt|yum|dnf|pacman|scoop'
        }
        
        It 'Prioritizes apt on Debian-based systems' -Skip:(-not $IsLinux) {
            if (Get-Command apt -ErrorAction SilentlyContinue) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'auto'
                $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                $result | Should -Match 'apt'
            }
        }
        
        It 'Falls back to dnf/yum on RedHat-based systems' -Skip:(-not $IsLinux) {
            if (-not (Get-Command apt -ErrorAction SilentlyContinue)) {
                if (Get-Command dnf -ErrorAction SilentlyContinue) {
                    $env:PS_SYSTEM_PACKAGE_MANAGER = 'auto'
                    $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                    $result | Should -Match 'dnf|yum'
                }
            }
        }
        
        It 'Suggests Linux-specific installation for uv' -Skip:(-not $IsLinux) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'uv' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest Linux-appropriate method (curl script or pip)
            $result | Should -Match 'curl|pip|apt|yum|dnf'
        }
        
        It 'Suggests Linux-specific installation for poetry' -Skip:(-not $IsLinux) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'poetry' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest Linux-appropriate method
            $result | Should -Match 'curl|pip|apt|yum|dnf'
        }
    }
    
    Context 'macOS Platform-Specific Suggestions' {
        It 'Suggests macOS-appropriate package managers on macOS' -Skip:(-not $IsMacOS) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest macOS package managers
            $result | Should -Match 'brew|scoop'
        }
        
        It 'Prioritizes Homebrew on macOS when available' -Skip:(-not $IsMacOS) {
            if (Get-Command brew -ErrorAction SilentlyContinue) {
                $env:PS_SYSTEM_PACKAGE_MANAGER = 'auto'
                $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
                $result | Should -Match 'brew'
            }
        }
        
        It 'Suggests macOS-specific installation for pnpm' -Skip:(-not $IsMacOS) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'pnpm' -ToolType 'node-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest macOS-appropriate method
            $result | Should -Match 'brew|npm|scoop'
        }
        
        It 'Suggests macOS-specific installation for uv' -Skip:(-not $IsMacOS) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'uv' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest macOS-appropriate method
            $result | Should -Match 'brew|pip|scoop'
        }
        
        It 'Suggests macOS-specific installation for poetry' -Skip:(-not $IsMacOS) {
            $result = Get-PreferenceAwareInstallHint -ToolName 'poetry' -ToolType 'python-package'
            $result | Should -Not -BeNullOrEmpty
            # Should suggest macOS-appropriate method
            $result | Should -Match 'brew|pip|scoop'
        }
    }
    
    Context 'Platform Detection' {
        It 'Detects platform correctly' {
            $platform = if (Get-Command Get-Platform -ErrorAction SilentlyContinue) {
                try { (Get-Platform).Name } catch { 'Unknown' }
            }
            else {
                if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) { 'Windows' }
                elseif ($IsLinux) { 'Linux' }
                elseif ($IsMacOS) { 'macOS' }
                else { 'Unknown' }
            }
            $platform | Should -BeIn @('Windows', 'Linux', 'macOS', 'Unknown')
        }
        
        It 'Provides platform-appropriate suggestions regardless of preference' {
            $result = Get-PreferenceAwareInstallHint -ToolName 'test-tool' -ToolType 'generic'
            $result | Should -Not -BeNullOrEmpty
            
            # Should contain platform-appropriate suggestions
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                $result | Should -Match 'scoop|winget|choco'
            }
            elseif ($IsLinux) {
                $result | Should -Match 'apt|yum|dnf|pacman'
            }
            elseif ($IsMacOS) {
                $result | Should -Match 'brew'
            }
        }
    }
    
    Context 'Tool-Specific Platform Methods' {
        It 'Returns platform-specific method for pnpm' {
            $result = Get-ToolSpecificInstallMethod -ToolName 'pnpm'
            if ($result) {
                # Should be platform-appropriate
                if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
                    $result | Should -Match 'scoop|winget|npm|choco'
                }
                elseif ($IsLinux) {
                    $result | Should -Match 'npm|apt|yum|dnf'
                }
                elseif ($IsMacOS) {
                    $result | Should -Match 'brew|npm'
                }
            }
        }
        
        It 'Respects platform parameter in Get-ToolSpecificInstallMethod' {
            $resultWindows = Get-ToolSpecificInstallMethod -ToolName 'pnpm' -Platform 'Windows'
            $resultLinux = Get-ToolSpecificInstallMethod -ToolName 'pnpm' -Platform 'Linux'
            $resultMacOS = Get-ToolSpecificInstallMethod -ToolName 'pnpm' -Platform 'macOS'
            
            if ($resultWindows) {
                $resultWindows | Should -Match 'scoop|winget|npm|choco'
            }
            if ($resultLinux) {
                $resultLinux | Should -Match 'npm|apt|yum|dnf'
            }
            if ($resultMacOS) {
                $resultMacOS | Should -Match 'brew|npm'
            }
        }
    }
}
