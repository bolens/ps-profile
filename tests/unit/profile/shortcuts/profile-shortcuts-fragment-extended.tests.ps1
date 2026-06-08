# ===============================================
# profile-shortcuts-fragment-extended.tests.ps1
# Execution tests for shortcuts.ps1 fragment behavior
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
    $script:EditorCommands = @(
        'code', 'code-insiders', 'codium', 'nvim', 'vim', 'emacs', 'micro', 'nano',
        'notepad++', 'sublime_text', 'atom', 'gedit', 'kate', 'leafpad', 'mousepad', 'xedit', 'notepad'
    )
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'shortcuts.ps1')
}

function script:Reset-ShortcutsCommandAvailability {
    Mark-TestCommandsUnavailable -CommandNames $script:EditorCommands
    if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
        Clear-TestCachedCommandCache | Out-Null
    }
}

Describe 'profile.d/shortcuts.ps1 extended scenarios' {
    BeforeEach {
        Reset-ShortcutsCommandAvailability
    }
    It 'Registers editor and navigation shortcut commands and aliases' {
        Get-Command Get-AvailableEditor -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Open-VSCode -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Open-Editor -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ProjectRoot -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command vsc -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command e -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command project-root -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-AvailableEditor returns the first available editor from the preference list' {
        Set-TestCommandAvailabilityState -CommandName 'nano' -Available $true

        $editor = Get-AvailableEditor
        $editor | Should -Not -BeNullOrEmpty
        $editor.Command | Should -Be 'nano'
    }

    It 'Get-AvailableEditor returns null when no preferred editors are available' {
        Get-AvailableEditor | Should -BeNullOrEmpty
    }
}
