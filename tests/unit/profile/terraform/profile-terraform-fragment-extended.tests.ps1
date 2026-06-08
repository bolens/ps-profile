<#
tests/unit/profile-terraform-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/terraform.ps1'
}
Describe 'profile.d/terraform.ps1 extended scenarios' {
    It 'Declares essential tier for infrastructure-as-code workflows' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Environment: cloud, development, iac-tools'
    }
    It 'Defines Invoke-Terraform guarded by command availability checks' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Terraform'
        $c | Should -Match 'Test-CachedCommand'
    }
    It 'Provides Invoke-TerraformApply helper for apply workflows' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-TerraformApply'
        $c | Should -Match 'PowerShell.Profile.Terraform'
    }
}
