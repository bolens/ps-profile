# ===============================================
# profile-files-module-registry-devtools-extended.tests.ps1
# Execution tests for Ensure-DevTools registry entries
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

Describe 'profile.d/files-module-registry.ps1 Ensure-DevTools registry extended scenarios' {
    It 'Maps Ensure-DevTools to dev-tools-modules entries' {
        $entries = $script:FileConversionModuleRegistry['Ensure-DevTools']
        ($entries | Where-Object { $_.Dir -like 'dev-tools-modules/*' }).Count | Should -BeGreaterThan 5
    }

    It 'Includes crypto formatting and data dev tool modules' {
        $files = $script:FileConversionModuleRegistry['Ensure-DevTools'] | ForEach-Object { $_.File }
        $files | Should -Contain 'hash.ps1'
        $files | Should -Contain 'jwt.ps1'
        $files | Should -Contain 'diff.ps1'
        $files | Should -Contain 'regex.ps1'
        $files | Should -Contain 'uuid.ps1'
        $files | Should -Contain 'units.ps1'
    }

    It 'Load-EnsureModules registers dev tools helpers from registry modules' {
        Load-EnsureModules -EnsureFunctionName 'Ensure-DevTools' -BaseDir $script:ProfileDir

        Get-Command Get-TextHash -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-Uuid -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-QrCodeSvg -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
