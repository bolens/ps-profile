# ===============================================
# profile-gh-fragment-extended.tests.ps1
# Execution tests for gh.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'gh.ps1')
}

Describe 'profile.d/gh.ps1 extended scenarios' {
    It 'Registers GitHub CLI helpers and aliases' {
        Get-Command Open-GitHubRepository -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitHubPullRequest -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command gh-open -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Open-GitHubRepository warns when gh is unavailable' {
        Set-TestCommandAvailabilityState -CommandName 'gh' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('gh', [ref]$null)
        }

        $output = Open-GitHubRepository 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'gh not found'
    }

    It 'Preserves existing gh helper bodies on repeated fragment loads' {
        $firstOpen = Get-Command Open-GitHubRepository -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'gh.ps1')

        (Get-Command Open-GitHubRepository -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstOpen.ScriptBlock.ToString()
    }
}
