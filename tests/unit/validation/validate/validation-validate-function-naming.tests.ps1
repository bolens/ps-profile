<#
tests/unit/validation-validate-function-naming.tests.ps1

.SYNOPSIS
    Behavioral unit tests for validate-function-naming.ps1 with isolated fixtures.
#>

function global:New-FunctionNamingFixtureDirectory {
    param(
        [switch]$IncludeInvalidFunction
    )

    $fixtureDir = Join-Path ([System.IO.Path]::GetTempPath()) ('FunctionNamingFixture-{0}' -f [System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $fixtureDir -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $fixtureDir 'good.ps1') -Value @'
function Get-NamingFixtureOk {
    'ok'
}
'@ -Encoding UTF8

    if ($IncludeInvalidFunction) {
        Set-Content -LiteralPath (Join-Path $fixtureDir 'bad.ps1') -Value @'
function Foo-NamingFixtureBad {
    'bad'
}
'@ -Encoding UTF8
    }

    return $fixtureDir
}

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
    $script:ValidateNamingScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'validate-function-naming.ps1'
    $script:ExceptionsFile = Join-Path $script:TestRepoRoot 'docs' 'guides' 'FUNCTION_NAMING_EXCEPTIONS.md'
    $ConfirmPreference = 'None'
}

Describe 'validate-function-naming.ps1 execution' {
    It 'Passes when fixture functions follow Verb-Noun naming conventions' {
        $fixtureDir = New-FunctionNamingFixtureDirectory
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:ValidateNamingScript -ArgumentList @(
                '-Path', $fixtureDir,
                '-ExceptionsFile', $script:ExceptionsFile
            )
            $result.ExitCode | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $fixtureDir) {
                Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when a fixture function does not follow Verb-Noun naming conventions' {
        $fixtureDir = New-FunctionNamingFixtureDirectory -IncludeInvalidFunction
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:ValidateNamingScript -ArgumentList @(
                '-Path', $fixtureDir,
                '-ExceptionsFile', $script:ExceptionsFile
            )
            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'Foo-NamingFixtureBad|Unapproved verb'
        }
        finally {
            if (Test-Path -LiteralPath $fixtureDir) {
                Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Passes when the requested analysis path contains no PowerShell files' {
        $emptyDir = New-TestTempDirectory -Prefix 'FunctionNamingEmptyPath'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:ValidateNamingScript -ArgumentList @(
                '-Path', $emptyDir,
                '-ExceptionsFile', $script:ExceptionsFile
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'passed with no issues|no issues'
        }
        finally {
            if (Test-Path -LiteralPath $emptyDir) {
                Remove-Item -LiteralPath $emptyDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
