<#
tests/unit/profile-files-ensure-conversion-media-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files.ps1'
}
Describe 'profile.d/files.ps1 Ensure-FileConversion-Media extended scenarios' {
    It 'Documents lazy media format conversion initializer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Ensure-FileConversion-Media'
        $c | Should -Match 'media format conversion utility functions on first use'
    }
    It 'Initializes image and audio modules in dependency order' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaImagesCommon'
        $c | Should -Match 'Initialize-FileConversion-MediaAudioCommon'
        $c | Should -Match 'Initialize-FileConversion-MediaPdf'
    }
    It 'Initializes color conversion modules ending with parse and convert' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaColorsNamed'
        $c | Should -Match 'Initialize-FileConversion-MediaColorsParse'
        $c | Should -Match 'FileConversionMediaInitialized'
    }
}
