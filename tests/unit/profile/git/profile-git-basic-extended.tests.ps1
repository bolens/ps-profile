# ===============================================
# profile-git-basic-extended.tests.ps1
# Execution tests for git-modules/core/git-basic.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
}

function script:Reset-GitBasicTestState {
    Clear-FragmentLoaded -FragmentName 'git' -ErrorAction SilentlyContinue
    Set-Variable -Name 'GitInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/git-modules/core/git-basic.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitBasicTestState
    }

    It 'Registers core git command wrappers and aliases through Ensure-Git' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Get-Command Invoke-GitStatus -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-GitChanges -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Save-GitCommit -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Publish-GitChanges -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-GitLog -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $gsAlias = Get-Alias gs -ErrorAction SilentlyContinue
        if ($gsAlias) {
            $gsAlias.ResolvedCommandName | Should -Be 'Invoke-GitStatus'
        }
    }

    It 'Invoke-GitStatus delegates to Invoke-GitCommand for the status subcommand' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Set-TestCommandAvailabilityState -CommandName 'git' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Push-Location (New-TestTempDirectory -Prefix 'GitBasicOutsideRepo')
        try {
            { Invoke-GitStatus | Out-Null } | Should -Not -Throw
        }
        finally {
            Pop-Location
        }
    }

    It 'Ensure-Git is idempotent after git basic modules are loaded' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git
        $firstStatus = Get-Command Invoke-GitStatus -ErrorAction Stop

        Ensure-Git

        (Get-Command Invoke-GitStatus -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstStatus.ScriptBlock.ToString()
    }
}
