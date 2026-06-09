# ===============================================
# profile-files-module-registry-media-extended.tests.ps1
# Execution tests for Ensure-FileConversion-Media registry entries
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
}

Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Media registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Media to media conversion modules' {
        $entries = $script:FileConversionModuleRegistry['Ensure-FileConversion-Media']
        ($entries | Where-Object { $_.Dir -like 'conversion-modules/media*' }).Count | Should -BeGreaterThan 10
    }

    It 'Includes image audio PDF and color conversion modules' {
        $files = $script:FileConversionModuleRegistry['Ensure-FileConversion-Media'] | ForEach-Object { $_.File }
        $files | Should -Contain 'common.ps1'
        $files | Should -Contain 'flac.ps1'
        $files | Should -Contain 'pdf.ps1'
        $files | Should -Contain 'named.ps1'
        $files | Should -Contain 'parse.ps1'
        $files | Should -Contain 'convert.ps1'
    }

    It 'Load-EnsureModules loads media conversion module initializers' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Media' -BaseDir $script:ProfileDir

        Get-Command Initialize-FileConversion-MediaImagesCommon -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-MediaAudioCommon -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-MediaPdf -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Initialize-FileConversion-MediaColorsConvert -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
