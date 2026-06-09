# ===============================================
# profile-system-editor-aliases-extended.tests.ps1
# Execution tests for system/EditorAliases.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'system.ps1')
}

function script:Reset-SystemFragmentState {
    Set-Variable -Name 'SystemInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/system/EditorAliases.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
        Ensure-System
    }

    It 'Registers Neovim editor helpers through Ensure-System' {
        Get-Command Open-Neovim -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Open-NeovimVi -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $vimAlias = Get-Alias vim -ErrorAction SilentlyContinue
        if ($vimAlias) {
            $vimAlias.ResolvedCommandName | Should -Be 'Open-Neovim'
        }

        $viAlias = Get-Alias vi -ErrorAction SilentlyContinue
        if ($viAlias) {
            $viAlias.ResolvedCommandName | Should -Be 'Open-NeovimVi'
        }
    }

    It 'Open-Neovim throws when nvim is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('nvim')
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { Open-Neovim | Out-Null } | Should -Throw '*nvim*'
    }

    It 'Open-Neovim does not throw when nvim is stubbed available' {
        Mark-TestCommandsUnavailable -CommandNames @('nvim')
        Set-TestCommandAvailabilityState -CommandName 'nvim' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Setup-CapturingCommandMock -CommandName 'nvim' -Output 'nvim stub invoked'

        { Open-Neovim --version | Out-Null } | Should -Not -Throw
    }
}
