<#
tests/unit/utility-fix-testsupport-imports.tests.ps1

.SYNOPSIS
    Behavioral unit tests for fix-testsupport-imports.ps1 on an isolated tree.
#>

function global:New-FixTestSupportImportsFixtureRepository {
    $repo = New-TestTempDirectory -Prefix 'FixTestSupportImportsFixture'
    $integrationDir = Join-Path $repo 'tests' 'integration' 'bootstrap'
    New-Item -ItemType Directory -Path $integrationDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $integrationDir 'noop.tests.ps1') -Value @'
BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
}
Describe 'noop' {
    It 'does nothing' { $true | Should -BeTrue }
}
'@ -Encoding UTF8

    $codeQualityDir = Join-Path $repo 'scripts' 'utils' 'code-quality'
    New-Item -ItemType Directory -Path $codeQualityDir -Force | Out-Null
    Copy-Item -LiteralPath $script:FixTestSupportImportsScript -Destination (Join-Path $codeQualityDir 'fix-testsupport-imports.ps1') -Force

    return $repo
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:FixTestSupportImportsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'fix-testsupport-imports.ps1'
    $ConfirmPreference = 'None'
}

Describe 'fix-testsupport-imports.ps1 execution' {
    It 'Reports zero fixes when TestSupport import paths are already correct' {
        $repo = New-FixTestSupportImportsFixtureRepository
        try {
            $scriptPath = Join-Path $repo 'scripts' 'utils' 'code-quality' 'fix-testsupport-imports.ps1'
            $result = Invoke-TestScriptFile -ScriptPath $scriptPath

            $result.ExitCode | Should -BeIn @(0, $null)
            $result.Output | Should -Match 'Fixed 0 file'
        }
        finally {
            if (Test-Path -LiteralPath $repo) {
                Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
