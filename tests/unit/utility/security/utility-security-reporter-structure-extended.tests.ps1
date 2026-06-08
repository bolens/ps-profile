<#
tests/unit/utility-security-reporter-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/security/modules/SecurityReporter.psm1'
}
Describe 'scripts/utils/security/modules/SecurityReporter.psm1 structure extended scenarios' {
    It 'Documents security scan reporting utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Security scan reporting utilities'
        $c | Should -Match 'SecurityReporter.psm1'
    }
    It 'Defines scan result processing and report writers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-SecurityScanResults'
        $c | Should -Match 'Write-SecurityReport'
        $c | Should -Match 'BlockingIssues'
    }
    It 'Imports CommonEnums for severity handling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CommonEnums.psm1'
        $c | Should -Match 'SeverityLevel'
        $c | Should -Match 'Export-ModuleMember'
    }
}
