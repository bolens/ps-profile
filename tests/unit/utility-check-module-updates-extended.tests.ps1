<#
tests/unit/utility-check-module-updates-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/check-module-updates.ps1'
}
Describe 'check-module-updates.ps1 extended scenarios' {
    It 'Documents Update DryRun and ModuleFilter parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.PARAMETER Update'
        $c | Should -Match 'DryRun'
        $c | Should -Match 'ModuleFilter'
    }
    It 'Checks PSScriptAnalyzer Pester and related modules' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'PSScriptAnalyzer'
        $c | Should -Match 'Pester'
    }
    It 'Supports scheduled update configuration' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Schedule'
        $c | Should -Match 'UpdateFrequency'
    }
    It 'Can save update reports to scripts/data' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ReportFile'
        $c | Should -Match 'scripts/data'
    }
}
