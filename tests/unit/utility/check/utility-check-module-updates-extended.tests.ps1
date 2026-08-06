<#
tests/unit/utility-check-module-updates-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/check-module-updates.ps1'
}
Describe 'check-module-updates.ps1 extended scenarios' {
    It 'Documents Update DryRun and ModuleFilter parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.PARAMETER Update'
        $c | Should -Match 'DryRun'
        $c | Should -Match 'ModuleFilter'
    }
    It 'loads module names from the canonical requirements manifest' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'requirements.+modules\.psd1'
        $c | Should -Match 'Import-PowerShellDataFile'
        $c | Should -Match 'Modules\.Keys'
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
