# ===============================================
# profile-modules-fragment-extended.tests.ps1
# Execution tests for modules.ps1 fragment behavior
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

function script:Reset-ModulesFragmentState {
    Clear-FragmentLoaded -FragmentName 'modules' -ErrorAction SilentlyContinue
    Remove-Variable -Name 'ModulesLoaded' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/modules.ps1 extended scenarios' {
    BeforeEach {
        Reset-ModulesFragmentState
    }

    It 'Registers lazy module enable helpers instead of eager Import-Module calls' {
        . (Join-Path $script:ProfileDir 'modules.ps1')

        Get-Command Enable-PoshGit -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Enable-PSReadLine -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'modules' | Should -Be $true
    }

    It 'Enable-PoshGit and Enable-PSReadLine execute without throwing' {
        . (Join-Path $script:ProfileDir 'modules.ps1')

        $global:LASTEXITCODE = 0
        { Enable-PoshGit } | Should -Not -Throw

        $global:LASTEXITCODE = 0
        { Enable-PSReadLine } | Should -Not -Throw
    }

    It 'Skips re-initialization when modules fragment is already loaded' {
        . (Join-Path $script:ProfileDir 'modules.ps1')
        $firstPoshGit = Get-Command Enable-PoshGit -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'modules.ps1')

        (Get-Command Enable-PoshGit -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstPoshGit.ScriptBlock.ToString()
    }
}
