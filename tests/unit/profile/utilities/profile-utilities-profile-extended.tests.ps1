# ===============================================
# profile-utilities-profile-extended.tests.ps1
# Execution tests for utilities-modules/system/utilities-profile.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
}

Describe 'profile.d/utilities-modules/system/utilities-profile.ps1 extended scenarios' {
    It 'Registers profile management helpers through Ensure-Utilities' {
        Get-Command Reload-Profile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Reload-Fragment -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $reloadAlias = Get-Alias reload -ErrorAction SilentlyContinue
        if ($reloadAlias) {
            $reloadAlias.ResolvedCommandName | Should -Be 'Reload-Profile'
        }
    }

    It 'Reload-Profile exposes a Fast switch parameter' {
        (Get-Command Reload-Profile -ErrorAction Stop).Parameters.ContainsKey('Fast') | Should -Be $true
    }

    It 'Allows repeated Ensure-Utilities calls without losing profile helpers' {
        Ensure-Utilities
        Ensure-Utilities

        Get-Command Reload-Profile -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
