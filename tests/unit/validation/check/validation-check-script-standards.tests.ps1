<#
tests/unit/validation-check-script-standards.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-script-standards.ps1 with isolated script fixtures.
#>

function global:New-ScriptStandardsFixture {
    param(
        [switch]$IncludeDirectExit
    )

    # Use system temp so Filter-Files -ExcludeTests does not skip fixtures under tests/test-data.
    $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('ScriptStandardsRepo-{0}' -f [System.Guid]::NewGuid())
    New-Item -ItemType Directory -Path $repo -Force | Out-Null
    $scriptsDir = Join-Path $repo 'scripts' 'utils'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $scriptsDir 'compliant.ps1') -Value @'
<#
.SYNOPSIS
    Compliant fixture script.
#>
param()
Write-Output 'ok'
'@

    if ($IncludeDirectExit) {
        Set-Content -LiteralPath (Join-Path $scriptsDir 'noncompliant.ps1') -Value @'
<#
.SYNOPSIS
    Noncompliant fixture script.
#>
param()
exit 2
'@
    }

    return @{
        RepositoryRoot = $repo
        ScriptsPath    = $scriptsDir
    }
}

function global:Invoke-ScriptStandardsCheck {
    param(
        [string]$ScriptsPath
    )

    $output = & pwsh -NoProfile -File $script:ScriptStandardsScript -Path $ScriptsPath 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
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
    $script:ScriptStandardsScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-script-standards.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-script-standards.ps1 execution' {
    It 'Passes when scripts only have informational findings' {
        $fixture = New-ScriptStandardsFixture
        try {
            Invoke-ScriptStandardsCheck -ScriptsPath $fixture.ScriptsPath | Select-Object -ExpandProperty ExitCode | Should -Be 0
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepositoryRoot) {
                Remove-Item -LiteralPath $fixture.RepositoryRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails when a script uses a direct exit call' {
        $fixture = New-ScriptStandardsFixture -IncludeDirectExit
        try {
            $result = Invoke-ScriptStandardsCheck -ScriptsPath $fixture.ScriptsPath

            $result.ExitCode | Should -BeIn @(1, 2)
            $result.Output | Should -Match 'noncompliant|direct exit|exit call'
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepositoryRoot) {
                Remove-Item -LiteralPath $fixture.RepositoryRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Fails parameter validation when the requested path does not exist' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'ScriptStandardsMissingPath') 'does-not-exist'
        try {
            $result = Invoke-ScriptStandardsCheck -ScriptsPath $missingPath

            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'Path does not exist|does not exist'
        }
        finally {
            $parent = Split-Path -Parent $missingPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
