# ===============================================
# profile-bootstrap-batch-loading-summary-extended.tests.ps1
# Execution tests for bootstrap/BatchLoadingSummary.ps1 behavior
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
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/bootstrap/BatchLoadingSummary.ps1 extended scenarios' {
    It 'Registers batch loading summary helpers' {
        Get-Command Initialize-BatchLoadingInfo -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Record-BatchLoading -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Show-BatchLoadingSummary -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Initialize-BatchLoadingInfo and Record-BatchLoading track batch metadata' {
        Initialize-BatchLoadingInfo
        Record-BatchLoading -BatchNumber 1 -TotalBatches 2 -FragmentCount 3 -FragmentNames @('a', 'b', 'c')

        $global:BatchLoadingInfo.Batches.Count | Should -Be 1
        $global:BatchLoadingInfo.Batches[0].FragmentCount | Should -Be 3
    }

    It 'Preserves batch summary helper bodies on repeated module loads' {
        $firstInit = Get-Command Initialize-BatchLoadingInfo -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'BatchLoadingSummary.ps1')

        (Get-Command Initialize-BatchLoadingInfo -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInit.ScriptBlock.ToString()
    }
}
