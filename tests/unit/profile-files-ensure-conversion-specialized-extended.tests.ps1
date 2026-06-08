<#
tests/unit/profile-files-ensure-conversion-specialized-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files.ps1'
}
Describe 'profile.d/files.ps1 Ensure-FileConversion-Specialized extended scenarios' {
    It 'Documents lazy specialized format conversion initializer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Ensure-FileConversion-Specialized'
        $c | Should -Match 'specialized format conversion utility functions on first use'
    }
    It 'Loads specialized modules from registry on first use' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Specialized'"
        $c | Should -Match 'FileConversionSpecializedInitialized'
    }
    It 'Delegates initialization to Initialize-FileConversion-Specialized loader' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Specialized'
        $c | Should -Match 'QR Code, JWT, Barcode'
    }
}
