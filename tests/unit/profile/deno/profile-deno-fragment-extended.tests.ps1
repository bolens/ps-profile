# ===============================================
# profile-deno-fragment-extended.tests.ps1
# Execution tests for deno.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'deno.ps1')
}

Describe 'profile.d/deno.ps1 extended scenarios' {
    It 'Registers deno runtime helpers and aliases' {
        Get-Command Invoke-Deno -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-DenoRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command deno -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Deno warns when deno is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'deno' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('deno', [ref]$null)
        }

        $output = Invoke-Deno --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'deno not found'
    }

    It 'Preserves existing deno helper bodies on repeated fragment loads' {
        $firstDenoRun = Get-Command Invoke-DenoRun -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'deno.ps1')

        (Get-Command Invoke-DenoRun -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstDenoRun.ScriptBlock.ToString()
    }
}
