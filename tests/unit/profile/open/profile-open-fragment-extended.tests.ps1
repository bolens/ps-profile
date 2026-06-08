# ===============================================
# profile-open-fragment-extended.tests.ps1
# Execution tests for open.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'open.ps1')
}

Describe 'profile.d/open.ps1 extended scenarios' {
    It 'Registers the Open-Item helper function' {
        $openCommand = Get-Command Open-Item -ErrorAction Stop
        $openCommand.CommandType | Should -Be 'Function'
    }

    It 'Open-Item returns without throwing when no path is provided' {
        { Open-Item } | Should -Not -Throw
    }

    It 'Preserves Open-Item on repeated fragment loads' {
        $firstOpen = Get-Command Open-Item -ErrorAction Stop
        . (Join-Path $script:ProfileDir 'open.ps1')
        (Get-Command Open-Item -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstOpen.ScriptBlock.ToString()
    }
}
