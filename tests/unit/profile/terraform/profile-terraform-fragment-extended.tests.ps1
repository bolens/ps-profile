# ===============================================
# profile-terraform-fragment-extended.tests.ps1
# Execution tests for terraform.ps1 fragment behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'terraform.ps1')
}

Describe 'profile.d/terraform.ps1 extended scenarios' {
    It 'Registers Invoke-Terraform and workflow helper commands' {
        Get-Command Invoke-Terraform -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-TerraformApply -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command tf -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Registers tf alias targeting Invoke-Terraform' {
        (Get-Alias tf).ResolvedCommandName | Should -Be 'Invoke-Terraform'
    }

    It 'Invoke-Terraform warns when terraform is unavailable' {
        Mark-TestCommandsUnavailable -CommandNames @('terraform')
        Set-TestCommandAvailabilityState -CommandName 'terraform' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('terraform', [ref]$null)
        }

        $output = Invoke-Terraform version 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'terraform not found'
    }
}
