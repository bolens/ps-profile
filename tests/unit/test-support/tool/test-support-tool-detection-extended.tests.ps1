<#
tests/unit/test-support-tool-detection-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/ToolDetection.ps1'
}
Describe 'tests/TestSupport/ToolDetection.ps1 extended scenarios' {
    It 'Documents tool detection and skip message utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tool detection and recommendation utilities'
        $c | Should -Match 'Get-TestToolSkipMessage'
        $c | Should -Match 'Skip-IfMikefarahYqUnavailable'
        $c | Should -Match 'Skip-IfMikefarahYqAvailable'
        $c | Should -Match 'Skip-IfToolUnavailable'
        $c | Should -Match 'Skip-IfNodeUnavailable'
        $c | Should -Match 'Skip-IfNpmPackagesUnavailable'
        $c | Should -Match 'Skip-IfPythonUnavailable'
        $c | Should -Match 'Skip-IfModuleUnavailable'
    }
    It 'Defines install command resolution helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Resolve-TestToolInstallCommand'
        $c | Should -Match 'Get-TestInstallCommandCandidates'
    }
    It 'Defines container engine availability mocks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-ContainerEngineAvailabilityMocks'
        $c | Should -Match 'Assert-ProfileCommandAlias'
    }
}

