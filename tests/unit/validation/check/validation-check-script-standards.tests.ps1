<#
tests/unit/validation/check/validation-check-script-standards.tests.ps1

.SYNOPSIS
    Behavioral tests for check-script-standards.ps1 using isolated fixtures.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $null -eq $current.Parent) { break }
        $current = $current.Parent
    }

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ScriptStandardsScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-script-standards.ps1'
}

Describe 'check-script-standards.ps1 execution' {
    BeforeEach {
        # Keep fixtures outside tests/ because the production filter excludes test paths.
        $script:FixtureRoot = New-TestExternalTempDirectory -Prefix 'ScriptStandards'
    }

    It 'accepts a script with the expected import and protected risky operation' {
        $content = @'
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath
try {
    Get-Content -LiteralPath 'fixture.txt'
}
catch {
    Write-Warning $_
}
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'compliant.ps1') -Value $content -Encoding UTF8

        $output = & $script:ScriptStandardsScript -Path $script:FixtureRoot 2>&1 | Out-String

        $output | Should -Match 'All scripts comply with codebase standards'
    }

    It 'reports informational import and error-handling findings' {
        $content = @'
Get-Content -LiteralPath 'fixture.txt'
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'informational.ps1') -Value $content -Encoding UTF8

        $output = & $script:ScriptStandardsScript -Path $script:FixtureRoot 2>&1 | Out-String

        $output | Should -Match 'informational issue'
    }

    It 'detects direct exits while allowing the Exit-WithCode implementation' {
        $content = @'
function Exit-WithCode {
    param([int]$Code)
    exit $Code
}

exit 2
'@
        Set-Content -LiteralPath (Join-Path $script:FixtureRoot 'exit-calls.ps1') -Value $content -Encoding UTF8

        {
            & $script:ScriptStandardsScript -Path $script:FixtureRoot
        } | Should -Throw '*1 issue(s) that need attention*'
    }

    It 'checks category-specific Common module import conventions' {
        foreach ($category in @('utils', 'checks', 'git')) {
            $categoryPath = Join-Path $script:FixtureRoot $category
            $null = New-Item -ItemType Directory -Path $categoryPath -Force
            $content = @'
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath
'@
            Set-Content -LiteralPath (Join-Path $categoryPath "$category.ps1") -Value $content -Encoding UTF8
        }

        $output = & $script:ScriptStandardsScript -Path $script:FixtureRoot 2>&1 | Out-String

        $output | Should -Match 'informational issue'
    }

    It 'ignores empty scripts' {
        [System.IO.File]::WriteAllText((Join-Path $script:FixtureRoot 'empty.ps1'), '')

        $output = & $script:ScriptStandardsScript -Path $script:FixtureRoot 2>&1 | Out-String

        $output | Should -Match 'All scripts comply with codebase standards'
    }

    It 'rejects a missing path during parameter validation' {
        $missingPath = Join-Path $script:FixtureRoot 'missing'

        {
            & $script:ScriptStandardsScript -Path $missingPath
        } | Should -Throw '*Path does not exist*'
    }
}
