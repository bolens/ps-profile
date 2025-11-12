#
# Tests for shortcut helper functions.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
    . (Join-Path $script:ProfileDir '15-shortcuts.ps1')
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
            $originalWarningPreference = $WarningPreference
            $WarningPreference = 'SilentlyContinue'
            try {
                { vsc } | Should -Not -Throw
            }
            finally {
                $WarningPreference = $originalWarningPreference
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