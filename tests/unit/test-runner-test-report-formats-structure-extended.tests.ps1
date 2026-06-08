<#
tests/unit/test-runner-test-report-formats-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestReportFormats.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestReportFormats.psm1 structure extended scenarios' {
    It 'Documents test report formatting utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test report formatting utilities'
        $c | Should -Match 'TestReportFormats.psm1'
    }
    It 'Defines custom report and format converters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-CustomTestReport'
        $c | Should -Match 'ConvertTo-HtmlReport'
        $c | Should -Match 'ConvertTo-MarkdownReport'
    }
    It 'Imports CommonEnums for report format types' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'CommonEnums.psm1'
        $c | Should -Match 'TestReportFormat'
        $c | Should -Match 'Export-ModuleMember'
    }
}
