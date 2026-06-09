# ===============================================
# profile-git-github-extended.tests.ps1
# Execution tests for git-modules/integrations/git-github.ps1 behavior
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
    $script:GitModulesDir = Join-Path $script:ProfileDir 'git-modules'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Import-GitHubIntegrationModule {
    foreach ($name in @('New-GitHubPullRequest', 'Show-GitHubPullRequest')) {
        Remove-Item -Path "Function:\global:$name" -ErrorAction SilentlyContinue
    }
    foreach ($aliasName in @('prc', 'prv')) {
        Remove-Item -Path "Alias:\global:$aliasName" -ErrorAction SilentlyContinue
    }

    . (Join-Path $script:GitModulesDir 'integrations/git-github.ps1')
}

Describe 'profile.d/git-modules/integrations/git-github.ps1 extended scenarios' {
    It 'Registers GitHub pull request helpers and aliases' {
        Import-GitHubIntegrationModule

        Get-Command New-GitHubPullRequest -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Show-GitHubPullRequest -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Alias prc -ErrorAction Stop).ResolvedCommandName | Should -Be 'New-GitHubPullRequest'
        (Get-Alias prv -ErrorAction Stop).ResolvedCommandName | Should -Be 'Show-GitHubPullRequest'
    }

    It 'New-GitHubPullRequest skips gh when the GitHub CLI is unavailable' {
        Import-GitHubIntegrationModule

        Setup-CapturingCommandMock -CommandName 'gh' -MarkAvailable $false
        Set-TestCommandAvailabilityState -CommandName 'gh' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { New-GitHubPullRequest -ErrorAction SilentlyContinue | Out-Null } | Should -Not -Throw
        $global:TestCommandInvocationCaptures.Count | Should -Be 0
    }

    It 'Preserves GitHub helper bodies on repeated module loads' {
        Import-GitHubIntegrationModule
        $firstCreate = Get-Command New-GitHubPullRequest -ErrorAction Stop

        Import-GitHubIntegrationModule

        (Get-Command New-GitHubPullRequest -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstCreate.ScriptBlock.ToString()
    }
}
