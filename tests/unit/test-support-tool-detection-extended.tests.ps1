<#
tests/unit/test-support-tool-detection-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/ToolDetection.ps1'
}
Describe 'tests/TestSupport/ToolDetection.ps1 extended scenarios' {
    It 'Documents tool detection and skip message utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tool detection and recommendation utilities'
        $c | Should -Match 'Get-TestToolSkipMessage'
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

