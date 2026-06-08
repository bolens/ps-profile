# ===============================================
# profile-cloud-enhanced-fragment-extended.tests.ps1
# Execution tests for cloud-enhanced.ps1 fragment behavior
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
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')

    $importCommand = Get-Command Import-FragmentModules -ErrorAction SilentlyContinue
    $script:TestImportFragmentModulesBody = if ($importCommand) { $importCommand.ScriptBlock } else { $null }
}

function script:Reset-CloudEnhancedFragmentState {
    foreach ($fragmentName in @('cloud-enhanced', 'cloud-azure', 'cloud-gcp', 'cloud-deploy')) {
        Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue
    }
}

Describe 'profile.d/cloud-enhanced.ps1 extended scenarios' {
    BeforeEach {
        if ($script:TestImportFragmentModulesBody) {
            Set-Item -Path Function:\Import-FragmentModules -Value $script:TestImportFragmentModulesBody -Force
        }

        Reset-CloudEnhancedFragmentState
    }

    It 'Loads azure, gcp, and deploy helpers through Import-FragmentModules' {
        . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')

        Get-Command Set-AzureSubscription -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Set-GcpProject -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Deploy-Vercel -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'cloud-enhanced' | Should -Be $true
    }

    It 'Skips re-initialization when cloud-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')
        $firstAzure = Get-Command Set-AzureSubscription -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'cloud-enhanced.ps1')

        (Get-Command Set-AzureSubscription -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstAzure.ScriptBlock.ToString()
    }
}
