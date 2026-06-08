<#
tests/unit/profile-dart-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dart.ps1'
}
Describe 'profile.d/dart.ps1 extended scenarios' {
    It 'Declares standard tier for dart and optional flutter package helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'dart or flutter'
    }
    It 'Defines Test-DartOutdated using dart pub outdated' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-DartOutdated'
        $c | Should -Match 'dart pub outdated'
    }
    It 'Provides flutter-outdated alias when flutter command is available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-FlutterOutdated'
        $c | Should -Match "Set-AgentModeAlias -Name 'flutter-outdated'"
    }
}
