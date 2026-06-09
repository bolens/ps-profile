# ===============================================
# profile-database-clients-fragment-extended.tests.ps1
# Execution tests for database-clients.ps1 fragment behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-DatabaseClientsFragmentState {
    Clear-FragmentLoaded -FragmentName 'database-clients' -ErrorAction SilentlyContinue
}

Describe 'profile.d/database-clients.ps1 extended scenarios' {
    BeforeEach {
        Reset-DatabaseClientsFragmentState
    }

    It 'Registers database client helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'database-clients.ps1')

        Get-Command Start-DBeaver -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-MongoDbCompass -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'database-clients' | Should -Be $true
    }

    It 'Start-DBeaver warns when dbeaver is unavailable' {
        . (Join-Path $script:ProfileDir 'database-clients.ps1')

        Set-TestCommandAvailabilityState -CommandName 'dbeaver' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('dbeaver', [ref]$null)
        }

        $output = Start-DBeaver 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'dbeaver not found'
    }

    It 'Skips re-initialization when database-clients is already loaded' {
        . (Join-Path $script:ProfileDir 'database-clients.ps1')
        $firstDBeaver = Get-Command Start-DBeaver -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'database-clients.ps1')

        (Get-Command Start-DBeaver -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstDBeaver.ScriptBlock.ToString()
    }
}
