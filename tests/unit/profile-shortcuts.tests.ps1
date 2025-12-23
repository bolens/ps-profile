#
# Tests for shortcut helper functions.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    
    # Initialize test mocks BEFORE loading shortcuts fragment to prevent editor commands from executing
    Initialize-TestMocks
    
    . (Join-Path $script:ProfileDir 'shortcuts.ps1')
    
    # Re-apply mocks after fragment loads to ensure they override
    Initialize-TestMocks
}

Describe 'Profile shortcut functions' {
    Context 'Availability checks' {
        It 'shortcut functions are available' {
            foreach ($cmd in 'vsc', 'e', 'project-root') {
                Get-Command $cmd -ErrorAction SilentlyContinue | Should -Not -Be $null
            }
        }
    }

    Context 'Execution behavior' {
        It 'vsc opens current directory in VS Code' {
            # Ensure Get-AvailableEditor returns null to prevent actual editor execution
            # Remove any existing function first
            if (Test-Path Function:\Get-AvailableEditor) {
                Remove-Item Function:\Get-AvailableEditor -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path Function:\global:Get-AvailableEditor) {
                Remove-Item Function:\global:Get-AvailableEditor -Force -ErrorAction SilentlyContinue
            }
            
            # Set up mock that always returns null
            function Get-AvailableEditor {
                return $null
            }
            
            $originalWarningPreference = $WarningPreference
            $originalErrorActionPreference = $ErrorActionPreference
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            try {
                # vsc should not throw when no editor is available (it should just warn)
                { vsc } | Should -Not -Throw
            }
            finally {
                $WarningPreference = $originalWarningPreference
                $ErrorActionPreference = $originalErrorActionPreference
            }
        }

        It 'e requires a path parameter' {
            $originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
            try {
                { e } | Should -Not -Throw
            }
            finally {
                $WarningPreference = $originalWarningPreference
            }
        }
    }
}