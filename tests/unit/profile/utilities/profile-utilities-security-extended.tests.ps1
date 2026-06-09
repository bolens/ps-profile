# ===============================================
# profile-utilities-security-extended.tests.ps1
# Execution tests for utilities-modules/system/utilities-security.ps1 behavior
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

Describe 'profile.d/utilities-modules/system/utilities-security.ps1 extended scenarios' {
    It 'Registers security helpers through Ensure-Utilities' {
        Get-Command Test-SafePath -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-RandomPassword -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $alias = Get-Alias pwgen -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'New-RandomPassword'
        }
    }

    It 'Test-SafePath rejects paths outside the base directory' {
        $baseDir = New-TestTempDirectory -Prefix 'UtilitiesSafePathBase'
        $inside = Join-Path $baseDir 'allowed.txt'
        Set-Content -LiteralPath $inside -Value 'ok' -Encoding UTF8

        Test-SafePath -Path $inside -BasePath $baseDir | Should -Be $true
        Test-SafePath -Path (Join-Path (Split-Path $baseDir -Parent) 'outside.txt') -BasePath $baseDir | Should -Be $false
    }

    It 'New-RandomPassword generates a 16-character password' {
        $password = New-RandomPassword
        $password.Length | Should -Be 16
        $password | Should -Match '^[A-Za-z0-9]+$'
    }
}
