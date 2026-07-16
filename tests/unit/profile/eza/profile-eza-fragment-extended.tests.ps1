# ===============================================
# profile-eza-fragment-extended.tests.ps1
# Execution tests for eza.ps1 fragment behavior
# ===============================================

function script:Import-EzaFragmentForTest {
    param(
        [switch]$EnsureAvailable
    )

    foreach ($aliasName in @('ls', 'l', 'll', 'la', 'lla', 'lt', 'lta', 'lg', 'llg', 'lS', 'ltime')) {
        if (Get-Alias -Name $aliasName -ErrorAction SilentlyContinue) {
            Remove-Item -Path "Alias:$aliasName" -Force -ErrorAction SilentlyContinue
        }
    }

    # Drop dispatcher proxies / prior helpers so Set-AgentModeFunction can register.
    $ezaHelpers = @(
        'Get-ChildItemEza'
        'Get-ChildItemEzaShort'
        'Get-ChildItemEzaLong'
        'Get-ChildItemEzaAll'
        'Get-ChildItemEzaAllLong'
        'Get-ChildItemEzaTree'
        'Get-ChildItemEzaTreeAll'
        'Get-ChildItemEzaGit'
        'Get-ChildItemEzaLongGit'
        'Get-ChildItemEzaBySize'
        'Get-ChildItemEzaByTime'
    )
    Remove-TestFunction -Name $ezaHelpers
    if (-not $global:AgentModeReplaceAllowed) {
        $global:AgentModeReplaceAllowed = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    }
    foreach ($helperName in $ezaHelpers) {
        [void]$global:AgentModeReplaceAllowed.Add($helperName)
    }

    if ($EnsureAvailable) {
        Mark-TestCommandsUnavailable -CommandNames @('eza')
        Set-TestCommandAvailabilityState -CommandName 'eza' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
    }

    . (Join-Path $script:ProfileDir 'eza.ps1')
}

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
    Import-EzaFragmentForTest -EnsureAvailable
}

Describe 'profile.d/eza.ps1 extended scenarios' {
    It 'Registers eza-backed listing functions when eza is available' {
        Get-Command Get-ChildItemEza -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ChildItemEzaLong -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ChildItemEzaTree -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-ChildItemEzaGit -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers ll and la aliases targeting eza listing helpers' {
        $ll = Get-Alias ll -ErrorAction Stop
        $la = Get-Alias la -ErrorAction Stop
        $(if ($ll.ResolvedCommandName) { $ll.ResolvedCommandName } else { $ll.Definition }) |
            Should -Be 'Get-ChildItemEzaLong'
        $(if ($la.ResolvedCommandName) { $la.ResolvedCommandName } else { $la.Definition }) |
            Should -Be 'Get-ChildItemEzaAll'
    }

    It 'Registers tree and git-aware listing aliases lt and lg' {
        $lt = Get-Alias lt -ErrorAction Stop
        $lg = Get-Alias lg -ErrorAction Stop
        $(if ($lt.ResolvedCommandName) { $lt.ResolvedCommandName } else { $lt.Definition }) |
            Should -Be 'Get-ChildItemEzaTree'
        $(if ($lg.ResolvedCommandName) { $lg.ResolvedCommandName } else { $lg.Definition }) |
            Should -Be 'Get-ChildItemEzaGit'
    }
}
