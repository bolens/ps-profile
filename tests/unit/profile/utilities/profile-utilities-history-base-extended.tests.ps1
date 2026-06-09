# ===============================================
# profile-utilities-history-base-extended.tests.ps1
# Execution tests for utilities-modules/history/utilities-history.ps1 behavior
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

Describe 'profile.d/utilities-modules/history/utilities-history.ps1 extended scenarios' {
    It 'Registers history viewing helpers through Ensure-Utilities' {
        Get-Command Get-History -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-History -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $alias = Get-Alias hg -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Find-History'
        }
    }

    It 'Get-History returns at most 20 entries' {
        $history = Get-History
        @($history).Count | Should -BeLessOrEqual 20
    }

    It 'Find-History accepts a search pattern without throwing' {
        { Find-History 'Ensure-Utilities' | Out-Null } | Should -Not -Throw
    }
}
