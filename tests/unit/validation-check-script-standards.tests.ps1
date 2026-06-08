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

    & pwsh -NoProfile -File $script:ScriptStandardsScript -Path $ScriptsPath 2>&1 | Out-Null
    return $LASTEXITCODE
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ScriptStandardsScript = Join-Path $script:TestRepoRoot 'scripts' 'checks' 'check-script-standards.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-script-standards.ps1 execution' {
    It 'Passes when scripts only have informational findings' {
        $fixture = New-ScriptStandardsFixture
        try {
            Invoke-ScriptStandardsCheck -ScriptsPath $fixture.ScriptsPath | Should -Be 0
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
            Invoke-ScriptStandardsCheck -ScriptsPath $fixture.ScriptsPath | Should -BeIn @(1, 2)
        }
        finally {
            if (Test-Path -LiteralPath $fixture.RepositoryRoot) {
                Remove-Item -LiteralPath $fixture.RepositoryRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
