<#
tests/unit/utility-module-update-notifier-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/modules/ModuleUpdateNotifier.psm1'
}
Describe 'scripts/utils/dependencies/modules/ModuleUpdateNotifier.psm1 structure extended scenarios' {
    It 'Documents module update notification utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module update notification utilities'
        $c | Should -Match 'ModuleUpdateNotifier.psm1'
    }
    It 'Defines Send-UpdateNotification email helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Send-UpdateNotification'
        $c | Should -Match 'Send-MailMessage'
        $c | Should -Match 'EmailOnlyOnUpdates'
    }
    It 'Exports notification function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'EmailSmtpServer'
        $c | Should -Match 'ReportData'
    }
}
