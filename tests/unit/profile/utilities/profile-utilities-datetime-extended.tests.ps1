# ===============================================
# profile-utilities-datetime-extended.tests.ps1
# Execution tests for utilities-modules/data/utilities-datetime.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
}

Describe 'profile.d/utilities-modules/data/utilities-datetime.ps1 extended scenarios' {
    It 'Registers epoch conversion helpers through Ensure-Utilities' {
        Get-Command ConvertFrom-Epoch -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-Epoch -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-Epoch -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-DateTime -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'ConvertFrom-Epoch and ConvertTo-Epoch round-trip a known timestamp' {
        $epoch = 1700000000
        $converted = ConvertFrom-Epoch -epoch $epoch
        ConvertTo-Epoch -date $converted.DateTime | Should -Be $epoch
    }

    It 'ConvertTo-Epoch and Get-Epoch return numeric timestamps' {
        $epoch = Get-Epoch
        $epoch | Should -BeGreaterThan 0
        ConvertTo-Epoch -date ([datetime]'2024-01-01T00:00:00') | Should -BeGreaterThan 0
    }
}
