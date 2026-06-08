<#
tests/unit/profile-files-ensure-file-utilities-extended.tests.ps1
#>
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files.ps1'
}
Describe 'profile.d/files.ps1 Ensure-FileUtilities extended scenarios' {
    It 'Documents lazy file utility initializer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Ensure-FileUtilities'
        $c | Should -Match 'file utility functions when any of them is called'
    }
    It 'Loads file utility modules from registry' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Load-EnsureModules -EnsureFunctionName ''Ensure-FileUtilities'''
        $c | Should -Match 'files-modules'
    }
    It 'Initializes head-tail hash size and hexdump modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileUtilities-HeadTail'
        $c | Should -Match 'Initialize-FileUtilities-Hash'
        $c | Should -Match 'Initialize-FileUtilities-HexDump'
    }
}

