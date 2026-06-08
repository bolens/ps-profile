# ===============================================
# profile-utilities-fragment-extended.tests.ps1
# Execution tests for utilities.ps1 fragment behavior
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
}

Describe 'profile.d/utilities.ps1 extended scenarios' {
    It 'Registers Ensure-Utilities and loads core utility commands' {
        Get-Command Ensure-Utilities -ErrorAction Stop | Should -Not -BeNullOrEmpty

        Ensure-Utilities

        Get-Command ConvertTo-IsbnNormalized -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-Isbn -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertFrom-Epoch -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Loads utility modules from the utilities-modules subdirectory' {
        $utilitiesModulesDir = Join-Path $script:ProfileDir 'utilities-modules'
        Test-Path -LiteralPath $utilitiesModulesDir | Should -Be $true

        Ensure-Utilities

        Get-Command ConvertFrom-UrlEncoded -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Export-IsbnBibliography -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Allows repeated Ensure-Utilities calls without losing registered commands' {
        Ensure-Utilities
        Ensure-Utilities

        Get-Command Test-IsbnValid -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-IsbnEditions -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
