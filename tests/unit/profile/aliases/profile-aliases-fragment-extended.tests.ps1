# ===============================================
# profile-aliases-fragment-extended.tests.ps1
# Execution tests for aliases.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'aliases.ps1')
}

function script:Reset-AliasesFragmentState {
    Remove-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction SilentlyContinue
    foreach ($name in @('Get-ChildItemEnhanced', 'Get-ChildItemEnhancedAll', 'Show-Path')) {
        Remove-Item -Path "Function:\global:$name" -Force -ErrorAction SilentlyContinue
    }
    foreach ($aliasName in @('ll', 'la')) {
        Remove-Item -Path "Alias:\global:$aliasName" -Force -ErrorAction SilentlyContinue
    }
}

Describe 'profile.d/aliases.ps1 extended scenarios' {
    BeforeEach {
        Reset-AliasesFragmentState
    }

    It 'Enable-Aliases registers ll, la, and Show-Path helpers' {
        Enable-Aliases

        Get-Alias ll -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Alias la -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Show-Path -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Variable -Name 'AliasesLoaded' -Scope Global -ErrorAction Stop).Value | Should -Be $true
    }

    It 'Show-Path returns PATH entries as a string array' {
        Enable-Aliases

        $pathEntries = @(Show-Path)
        @($pathEntries).Count | Should -BeGreaterThan 0
        $pathEntries[0] | Should -BeOfType [string]
    }

    It 'Skips re-registration when AliasesLoaded is already set' {
        Enable-Aliases
        $firstShowPath = Get-Command Show-Path -ErrorAction Stop

        Enable-Aliases

        (Get-Command Show-Path -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstShowPath.ScriptBlock.ToString()
    }
}
