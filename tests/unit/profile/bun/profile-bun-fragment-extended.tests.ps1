# ===============================================
# profile-bun-fragment-extended.tests.ps1
# Execution tests for bun.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'bun.ps1')
}

Describe 'profile.d/bun.ps1 extended scenarios' {
    It 'Registers bun runtime helpers and aliases' {
        Get-Command Invoke-Bunx -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-BunRun -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command bunx -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-Bunx warns when bun is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'bun' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('bun', [ref]$null)
        }

        $output = Invoke-Bunx --version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'bun not found'
    }

    It 'Preserves existing bun helper bodies on repeated fragment loads' {
        $firstBunRun = Get-Command Invoke-BunRun -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'bun.ps1')

        (Get-Command Invoke-BunRun -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstBunRun.ScriptBlock.ToString()
    }
}
