<#
tests/unit/profile-main-loader-common-enums-extended.tests.ps1
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
    $script:ProfileScript = Join-Path $script:TestRepoRoot 'Microsoft.PowerShell_profile.ps1'
}
Describe 'Microsoft.PowerShell_profile.ps1 CommonEnums bootstrap extended scenarios' {
    It 'Documents CommonEnums early import section' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'COMMON ENUMS - MUST BE LOADED FIRST'
        $c | Should -Match 'CommonEnums.psm1'
        $c | Should -Match 'parse time'
    }
    It 'Imports CommonEnums globally before fragment modules' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Import-Module .+commonEnumsModule'
        $c | Should -Match '-Force -Global'
        $c | Should -Match 'FileSystemPathType'
    }
    It 'Warns on CommonEnums import failure when debug enabled' {
        $c = Get-Content -LiteralPath $script:ProfileScript -Raw
        $c | Should -Match 'Failed to load CommonEnums module'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
}
