<#
tests/unit/utility-migrate-conversion-integration-tests.tests.ps1

.SYNOPSIS
    Behavioral unit tests for migrate-conversion-integration-tests.ps1 dry-run mode.
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
    $script:MigrateConversionTestsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'migrate-conversion-integration-tests.ps1'
    $ConfirmPreference = 'None'
}

Describe 'migrate-conversion-integration-tests.ps1 execution' {
    It 'Completes in WhatIfOnly mode without modifying test files' {
        $sampleTest = Join-Path $script:TestRepoRoot 'tests' 'integration' 'conversion' 'data' 'structured' 'ini.tests.ps1'
        if (-not (Test-Path -LiteralPath $sampleTest)) {
            Set-ItResult -Skipped -Because 'conversion integration tests are not present'
            return
        }

        $beforeWrite = (Get-Item -LiteralPath $sampleTest).LastWriteTimeUtc
        $result = Invoke-TestScriptFile -ScriptPath $script:MigrateConversionTestsScript -ArgumentList @(
            '-RepoRoot', $script:TestRepoRoot,
            '-WhatIfOnly'
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Migration complete'
        (Get-Item -LiteralPath $sampleTest).LastWriteTimeUtc | Should -Be $beforeWrite
    }

    It 'Previews migration for legacy Initialize-TestProfile calls in an isolated tree' {
        $repo = New-TestTempDirectory -Prefix 'MigrateConversionFixture'
        $conversionDir = Join-Path $repo 'tests' 'integration' 'conversion' 'data' 'legacy'
        $testFile = Join-Path $conversionDir 'legacy.tests.ps1'
        try {
            New-Item -ItemType Directory -Path $conversionDir -Force | Out-Null
            Set-Content -LiteralPath $testFile -Value @'
BeforeAll {
    Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
}
Describe 'legacy conversion test' {
    It 'still loads' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:MigrateConversionTestsScript -ArgumentList @(
                '-RepoRoot', $repo,
                '-WhatIfOnly'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Would update:.*legacy\.tests\.ps1'
            $result.Output | Should -Match 'Migration complete\. Files changed: 1'
            (Get-Content -LiteralPath $testFile -Raw) | Should -Match 'Initialize-TestProfile'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Applies migration for legacy Initialize-TestProfile calls in an isolated tree' {
        $repo = New-TestTempDirectory -Prefix 'MigrateConversionApply'
        $conversionDir = Join-Path $repo 'tests' 'integration' 'conversion' 'data' 'legacy-apply'
        $testFile = Join-Path $conversionDir 'legacy-apply.tests.ps1'
        try {
            New-Item -ItemType Directory -Path $conversionDir -Force | Out-Null
            Set-Content -LiteralPath $testFile -Value @'
BeforeAll {
    Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
}
Describe 'legacy conversion test apply' {
    It 'still loads' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:MigrateConversionTestsScript -ArgumentList @(
                '-RepoRoot', $repo
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Updated:.*legacy-apply\.tests\.ps1'
            $result.Output | Should -Match 'Migration complete\. Files changed: 1'
            $updated = Get-Content -LiteralPath $testFile -Raw
            $updated | Should -Match 'Initialize-ConversionIntegrationForTestFile'
            $updated | Should -Not -Match 'LoadConversionModules'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
