<#
tests/unit/profile-minio-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/minio.ps1'
}
Describe 'profile.d/minio.ps1 extended scenarios' {
    It 'Declares essential tier for MinIO mc client helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'PowerShell.Profile.Minio'
    }
    It 'Defines Get-MinioFileList wrapping mc ls' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-MinioFileList'
        $c | Should -Match 'mc ls'
    }
    It 'Registers mc-ls and mc-cp aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'mc-ls'"
        $c | Should -Match "Set-AgentModeAlias -Name 'mc-cp'"
    }
}
