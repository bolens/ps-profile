<#
tests/unit/profile-bootstrap-embedded-install-hints-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/EmbeddedInstallHints.ps1'
}
Describe 'profile.d/bootstrap/EmbeddedInstallHints.ps1 extended scenarios' {
    It 'Documents embedded install hint expansion for Node and Python' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EmbeddedInstallHints.ps1'
        $c | Should -Match 'embedded conversion scripts'
    }
    It 'Defines Get-NodePackageInstallCommandCore and Get-PythonPackageInstallCommandCore' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-NodePackageInstallCommandCore'
        $c | Should -Match 'Get-PythonPackageInstallCommandCore'
        $c | Should -Match 'Get-NodePackageInstallRecommendation'
    }
    It 'Defines Expand-EmbeddedNodeInstallHints and Resolve-PythonInstallHintMessage' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Expand-EmbeddedNodeInstallHints'
        $c | Should -Match 'Expand-EmbeddedPythonInstallHints'
        $c | Should -Match 'Resolve-PythonInstallHintMessage'
    }
}
