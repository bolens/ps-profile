# ===============================================
# profile-editors-fragment-extended.tests.ps1
# Execution tests for editors.ps1 fragment behavior
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

function script:Reset-EditorsFragmentState {
    Clear-FragmentLoaded -FragmentName 'editors' -ErrorAction SilentlyContinue
}

Describe 'profile.d/editors.ps1 extended scenarios' {
    BeforeEach {
        Reset-EditorsFragmentState
    }

    It 'Registers editor integration helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'editors.ps1')

        Get-Command Edit-WithVSCode -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Edit-WithCursor -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Edit-WithNeovim -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'editors' | Should -Be $true
    }

    It 'Edit-WithVSCode warns when no supported VS Code binary is available' {
        . (Join-Path $script:ProfileDir 'editors.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('code', 'code-insiders', 'codium')
        foreach ($tool in @('code', 'code-insiders', 'codium')) {
            Set-TestCommandAvailabilityState -CommandName $tool -Available $false
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('vscode', [ref]$null)
        }

        $output = Edit-WithVSCode 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'vscode not found'
    }

    It 'Skips re-initialization when editors fragment is already loaded' {
        . (Join-Path $script:ProfileDir 'editors.ps1')
        $firstNeovim = Get-Command Edit-WithNeovim -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'editors.ps1')

        (Get-Command Edit-WithNeovim -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstNeovim.ScriptBlock.ToString()
    }
}
