<#
tests/unit/test-runner-test-watcher-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestWatcher.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestWatcher.psm1 structure extended scenarios' {
    It 'Documents test file watcher for development workflows' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestWatcher.psm1'
        $c | Should -Match 'watcher'
    }
    It 'Defines Start-TestWatcher and watcher cleanup helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-TestWatcher'
        $c | Should -Match 'Stop-TestWatcherResources'
    }
    It 'Exports watcher registration functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'New-RegisteredTestWatcher'
    }
}

