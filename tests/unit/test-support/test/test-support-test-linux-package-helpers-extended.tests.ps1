<#
tests/unit/test-support-test-linux-package-helpers-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestLinuxPackageHelpers.ps1'
}
Describe 'tests/TestSupport/TestLinuxPackageHelpers.ps1 extended scenarios' {
    It 'Documents Linux system package availability utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestLinuxPackageHelpers.ps1'
        $c | Should -Match 'Linux system package'
    }
    It 'Defines Test-LinuxSystemPackageAvailable helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-LinuxSystemPackageAvailable'
    }
    It 'Supports optional tooling detection on Linux hosts' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'dpkg'
        $c | Should -Match 'rpm'
        $c | Should -Match 'pacman'
    }
}

